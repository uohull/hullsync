# JWT Authentication
__Reference__: https://docs.box.com/docs/app-auth

## Getting all of the information for JWT

### 1. Generating RSA key pair
```
cd ~/hullsync
$ openssl genrsa -aes256 -out box_private_key.pem 2048
```
> WIll be asked for a passphrase. This pasphrase is referred to as JWT_PRIVATE_KEY_PASSWORD      
> Add one and remember it as it is needed for the next step and later     
> The location of this file is from the root of the application i.e. _box_private_key.pem_ will be the value for JWT_PRIVATE_KEY_FILE
```
$ openssl rsa -pubout -in box_private_key.pem -out box_public_key.pem
```
> The files box_private_key.pem and box_public_key.pem should have been created

### 2. Add public key to the box application
* Visit the URL https://app.box.com/developers/services/ 
* Find your app and click on edit application
* Goto the section public key management, click on add key and add the contents from the file __box_public_key.pem__, verify and save
* There should be an id visible. Copy it. This id is referred to as JWT_PUBLIC_KEY_ID

### 3. Client ID and secret 
* Visit the URL https://app.box.com/developers/services/ 
* Find your app and click on edit application
* Get the client Id and client secret from the section OAuth2 Parameters
* This is the BOX_CLIENT_ID and BOX_CLIENT_SECRET

### 4. Enterprise ID or user ID    
* Follow the steps detailed in [oauth2Tokens](https://github.com/uohull/hullsync/blob/master/doc/oauth2Tokens.md) to get the access and refresh tokens
* Save the BOX_CLIENT_ID and BOX_CLIENT_SECRET to the .env file (see step below)
* Get the user Id from the box client
```
cd ~/hullsync
rails c
```
```
b = BoxClient()
b.user_id
```
* This is the BOX_USER_ID (It may as well be the BOX_ENTERPRISE_ID. I am not sure)

## Saving the information in .env file
The ruby box client [Boxr](https://github.com/cburnette/boxr) uses dotenv to store and read config values

Create a file called .env in the home of the application
```
touch ~/hullsync/.env
```
Add the following into the .env file
```
BOX_CLIENT_ID=
BOX_CLIENT_SECRET=
BOX_ENTERPRISE_ID=
BOX_USER_ID=
JWT_PRIVATE_KEY_FILE=
JWT_PRIVATE_KEY_PASSWORD=
JWT_PUBLIC_KEY_ID=
```
## JWT - Authenticating as an enterprise user
```
$ cd ~/hullsync
$ rails c
```
```
require 'boxr'
client = Boxr::Client.new('', jwt_private_key: File.read(ENV['JWT_PRIVATE_KEY_FILE']))
client.folder_items(Boxr::ROOT)
```
> I get the error bad authentication header.

Digging into the code, I was able to get a bit more information     
https://github.com/cburnette/boxr/blob/master/lib/boxr/client.rb    
https://github.com/cburnette/boxr/blob/master/lib/boxr/auth.rb
```
$ cd ~/hullsync
$ rails c
```
```
Boxr.get_enterprise_token(private_key: File.read(ENV['JWT_PRIVATE_KEY_FILE']))
```
> Boxr::BoxrError: 400: {"error":"invalid_grant","error_description":"Please check the 'sub' claim."}    
> So it looks like the id is of type user

## JWT - Authenticating as a normal user
```
$ cd ~/hullsync
$ rails c
```
```
> require 'boxr'
> client = Boxr::Client.new('', jwt_private_key: File.read(ENV['JWT_PRIVATE_KEY_FILE']), as_user=ENV['BOX_USER_ID'], enterprise_id: nil)
> client.folder_items(Boxr::ROOT)
```
> I get the error bad authentication header.

Digging into the code, I was able to get a bit more information    
https://github.com/cburnette/boxr/blob/master/lib/boxr/client.rb    
https://github.com/cburnette/boxr/blob/master/lib/boxr/auth.rb
```
$ cd ~/hullsync
$ rails c
```
```
Boxr.get_user_token(ENV['BOX_USER_ID'], private_key: File.read(ENV['JWT_PRIVATE_KEY_FILE']))
```
> Boxr::BoxrError: 400: {"error":"unauthorized_client","error_description":"This app is not authorized by the enterprise admin"}    
> I need to get authorization from the enterprise admin
