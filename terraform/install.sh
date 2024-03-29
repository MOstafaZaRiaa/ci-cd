
#!/bin/bash
sudo yum install -y nodejs
sudo npm install pm2@latest -g
pm2 startup
