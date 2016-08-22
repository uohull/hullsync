# Extracting access and refresh tokens for Oauth2 access

* Log-in to hull box from your local browser with ___archivematica___ account

* Go to the home directory of the hullsync app     
```cd ~/hullsync```

* Run the script lib/oauth.rb
```ruby lib/oauth.rb```

* Copy the URL printed on screen to your local browser and visit the page (ensure the client id is included in the url)

* It will redirect to https://hullsync.cottagelabs.com/tokens (don't worry if the URL does not exist or if https is not configured)

* Copy the value for the code from the redirect url and paste it into the console <br> __NOTE__ You need to be quick as the code generated in valid only for 30 seconds

* It will return the access token and refresh tokens. <br> These are saved to the file location _BOX_ACCESS_TOKEN_FILE_ and _BOX_REFRESH_TOKEN_FILE_
defined in the [.env file](https://github.com/uohull/hullsync/blob/master/doc/envFormat.md). <br> The access token is valid for an hour. The refresh token is valid for 60 days. <br> You could define these values in the .env file as follows
```
cd ~/hullsync
touch .env
vim .env
```
```
BOX_ACCESS_TOKEN_FILE=.box_access_token
BOX_REFRESH_TOKEN_FILE=.box_refreh_token
```
 
* Once we do this we can access the client api using these credentials for the next hour.
* We can use these two tokens in the boxr client and generate new tokens. So as long as the app is continuously running and we keep refreshing our tokens, we can use them for ever.
* As long as the app is running and continually accessed, Boxr can refresh the tokens with a callback
 
## Questions
1. Should we write the access and refresh tokens to file periodically while boxr is running

2. If we think the app is not going to be accessed atleast once every 30 minutes, do we manage tokens ourselves
    * Every time a call is made using the boxr client, check the time since initialization and if greater than 50 minutes, re-initialize the client
    * Do we run a separate task that refreshes tokens every 45 minutes

# NOTE
 * Using [Boxr gem](https://github.com/cburnette/boxr) to talk to Box API (as suggested by [Box](https://docs.box.com/page/sdks))
 
 * The method described here uses [OAuth2 authentication]()
 
 * The other solution to overcome this problem seems to be [JWT authentication](https://docs.box.com/docs/app-auth)
     * I got as far as [Step 5](https://docs.box.com/docs/app-auth#section-5-constructing-the-claims) but got stuck here as I didn't know the values for _enterprise_id_ or _user_id_
     * This [post](https://community.box.com/t5/Developer-Forum/User-id-in-Authentication-with-JWT/td-p/19772) suggests getting the _enterprise_id_ from the [app settings page](https://app.box.com/master/settings) and then using that to generate a new user and get the _user_id_ for that user.
     * I couldn't spot the _enterprise_id_ in the app settings page. Is it the email used to login? 
     * Also, we don't want to generate a new user, but use the id of the _archivematica_ user.  