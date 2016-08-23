# Instructions to Install and configure davfs2 on Ubuntu for box

__Reference:__     
https://uisapp2.iu.edu/confluence-prd/display/SOICKB/Using+Box+under+Linux    
Section Mounting Box (davfs2)    

1. Install davfs2
```
sudo apt-get install davfs2
```

2. Create folder to mount davfs
```
mkdir /home/cluser/box
```

3. Make sure davfs2 user has access to the folder     
Add user to davfs2 group
```
sudo usermod -a -G davfs2 cluser
```
login and logout for this to be recognized

4. Add the "use_locks 0" configuration option to /etc/davfs2/davfs2.conf
```
sudo vim /etc/davfs2/davfs2.conf
```
search for the line use_locks (likely commented).         
Copy the line, remove the comment and set the value to 0 and save the file

5. Enable mounting of folder    
Add the following entry to /etc/fstab that looks like this    
```
sudo vim /etc/fstab
```
```
https://dav.box.com/dav/ /home/username/box davfs rw,user,noauto
```

6. Copy the /etc/davfs2 directory to .davfs2 in your home directory    
```
sudo cp -r /etc/davfs2 ~/.davfs2
```

7. Add box credentials to davfs secrets file        
Create a file called 'secrets' in ~/.davfs2/
```
vim ~/.davfs2/secrets
```
Add just one line to the file of the format    
```
https://dav.box.com/dav box_user_email box_password
```
Change permissions so only the user can read it
```
chmod 600 ~/.davfs2/secret
```
__Note:__    
For the box_password, do not use the sso password of the account, but create an external password.         
See https://kb.iu.edu/d/bccp for instructions    

8. To mount the box folder
```
mount /home/cluser/box 
```

9. To unmount the box folder
```
fusermount -u /home/username/box
```