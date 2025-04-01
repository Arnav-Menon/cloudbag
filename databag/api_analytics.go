package databag

import (
    "databag/internal/store"
    "encoding/json"
    "net/http"
    "time"
    "strconv"
)

type UserAnalytics struct {
    TotalNewUsers int64 `json:"totalNewUsers"`
}

type MediaAnalytics struct {
    TotalUploads int64 `json:"totalUploads"`
}

type UserMediaItem struct {
    AssetID   string `json:"assetId"`
    Filename  string `json:"filename"`
    MediaType string `json:"mediaType"`
    Created   int64  `json:"created"`
    TopicID   string `json:"topicId,omitempty"`
    ChannelID string `json:"channelId,omitempty"`
}

type UserMedia struct {
    Username string         `json:"username"`
    Media    []UserMediaItem `json:"media"`
}

type NewUserItem struct {
    Username  string `json:"username"`
    GUID      string `json:"guid"`
    Created   int64  `json:"created"`
}

// GetAnalytics returns user and media analytics data
func GetAnalytics(w http.ResponseWriter, r *http.Request) {
    // Verify admin token
    token := r.FormValue("token")
    access := getStrConfigValue(CNFAdminSession, "")
    if token == "" || token != access {
        ErrResponse(w, http.StatusUnauthorized, nil)
        return
    }

    // Get parameters
    timeRange := r.FormValue("timeRange")
    if timeRange == "" {
        timeRange = "24h" // Default to 24 hours
    }

    // Calculate time threshold (default 24 hours ago)
    var timeThreshold int64
    now := time.Now().Unix()
    switch timeRange {
    case "24h":
        timeThreshold = now - (24 * 60 * 60)
    case "7d":
        timeThreshold = now - (7 * 24 * 60 * 60)
    case "30d":
        timeThreshold = now - (30 * 24 * 60 * 60)
    default:
        timeThreshold = now - (24 * 60 * 60)
    }

    // Get new users count in the last 24 hours
    var newUserCount int64
    if err := store.DB.Model(&store.Account{}).
        Where("created > ?", timeThreshold).
        Count(&newUserCount).Error; err != nil {
        ErrResponse(w, http.StatusInternalServerError, err)
        return
    }

    // Get new user details
    var newUsers []NewUserItem
    if err := store.DB.Model(&store.Account{}).
        Where("created > ?", timeThreshold).
        Select("username, guid, created").
        Scan(&newUsers).Error; err != nil {
        ErrResponse(w, http.StatusInternalServerError, err)
        return
    }

    // Get media uploads count in the last 24 hours
    var mediaUploads int64
    if err := store.DB.Model(&store.Asset{}).
        Where("created > ?", timeThreshold).
        Where("transform = '' OR transform IS NULL"). // filter out transforms, only count originals
        Count(&mediaUploads).Error; err != nil {
        ErrResponse(w, http.StatusInternalServerError, err)
        return
    }

    // Get media uploads grouped by username
    var uploaderIDs []uint
    if err := store.DB.
        Model(&store.Asset{}).
        Where("created > ? AND (transform = '' OR transform IS NULL)", timeThreshold).
        Distinct("account_id").
        Pluck("account_id", &uploaderIDs).Error; err != nil {
        ErrResponse(w, http.StatusInternalServerError, err)
        return
    }

    var mediaByUser []UserMedia

    // Step 2: Iterate over uploader IDs and fetch their media uploads
    for _, uploaderID := range uploaderIDs {
        var account store.Account
        if err := store.DB.First(&account, uploaderID).Error; err != nil {
            continue // Skip if account not found
        }

        var mediaItems []UserMediaItem
        if err := store.DB.Raw(`
            SELECT
                ast.asset_id AS asset_id,
                ast.asset_id AS filename,      -- Using asset_id as filename (no filename column)
                ast.status AS media_type,        -- Using status as media_type (no media_type column)
                ast.created AS created,
                CAST(ast.topic_id AS CHAR) AS topic_id,
                CAST(ast.channel_id AS CHAR) AS channel_id
            FROM assets ast
            WHERE ast.account_id = ?
            AND ast.created > ?
            AND (ast.transform = '' OR ast.transform IS NULL)
            ORDER BY ast.created DESC
        `, uploaderID, timeThreshold).Scan(&mediaItems).Error; err != nil {
            LogMsg(err.Error())
            continue
        }

        if len(mediaItems) > 0 {
            username := account.Username
            if username == "" {
                username = "account_" + strconv.FormatUint(uint64(account.ID), 10)
            }
            mediaByUser = append(mediaByUser, UserMedia{
                Username: username,
                Media:    mediaItems,
            })
        }
    }

    w.Header().Set("Content-Type", "text/plain")

    // Output each new user record as a JSON line
    for _, user := range newUsers {
        rec := map[string]interface{}{
            "username":    user.Username,
            "guid":        user.GUID,
            "created":     user.Created,
            "record_type": "user",
        }
        b, err := json.Marshal(rec)
        if err != nil {
            continue
        }
        w.Write(b)
        w.Write([]byte("\n"))
    }

    // Output each media record as a JSON line
    for _, um := range mediaByUser {
        for _, item := range um.Media {
            rec := map[string]interface{}{
                "assetId":    item.AssetID,
                "filename":   item.Filename,
                "mediaType":  item.MediaType,
                "created":    item.Created,
                "topicId":    item.TopicID,
                "channelId":  item.ChannelID,
                "username":   um.Username,
                "record_type": "photo",
            }
            b, err := json.Marshal(rec)
            if err != nil {
                continue
            }
            w.Write(b)
            w.Write([]byte("\n"))
        }
    }
}
