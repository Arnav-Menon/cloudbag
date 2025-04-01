package databag

import (
    "io/ioutil"
    "os"
    "path/filepath"
)

// SaveAdminTokenToFile saves the admin token to a file
func SaveAdminTokenToFile(token string) error {
    // Define the directory where token will be saved
    tokenDir := "/var/lib/token_data"
    
    // Create directory if it doesn't exist
    if err := os.MkdirAll(tokenDir, 0700); err != nil {
        return err
    }

    // Define token file path
    tokenPath := filepath.Join(tokenDir, "adminToken.txt")
    
    // Write token to file with secure permissions
    return ioutil.WriteFile(tokenPath, []byte(token), 0600)
}