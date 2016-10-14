# Format of ENV file

Create a file called .env in the base of the hullsync application
 ```
 cd ~/hullsync
 touch .env
 ```
 
The following environment variables are read from the file    
```
BOX_CLIENT_ID=    
BOX_CLIENT_SECRET=
BOX_ENTERPRISE_ID=
BOX_USER_ID=
JWT_PRIVATE_KEY_FILE=
JWT_PRIVATE_KEY_PASSWORD=
JWT_PUBLIC_KEY_ID=
BOX_ACCESS_TOKEN_FILE=
BOX_REFRESH_TOKEN_FILE=
BOX_ROOT_DIR= 
BAGIT_ROOT_DIR=
HULL_SYNC_USER_LOGIN_EMAIL=
 ```

BOX_ROOT_DIR is the location where box is mounted using DavFS (~/box). See doc [InstallAndConfigureDavfs](https://github.com/uohull/hullsync/blob/master/doc/InstallAndConfigureDavfs.md) for more information.
    
BAGIT_ROOT_DIR is the location where the box folders are to be copied for preparing the bagit. Give the fullpath to the folder. For example '/home/cluser/bagit_processing'

HULL_SYNC_USER_LOGIN_EMAIL is the user with whom researchers share their data and the application is based on.

BOX_ACCESS_TOKEN_FILE and BOX_REFRESH_TOKEN_FILE are the locations of the access and refresh token as explained in the doc [oauth2Tokens](https://github.com/uohull/hullsync/blob/master/doc/oauth2Tokens.md)
 
All other values are for defined in the doc [JWTAuthentication](https://github.com/uohull/hullsync/blob/master/doc/JWTAuthentication.md)