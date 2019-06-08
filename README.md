# Building your own emailServer (WTmail) - "Under constrution"
## ¿What is it?
It is a Linux mail server based on the protocols:
* SMTP (Simple Mail Transfer Protocol)
* POP3 (Post Office Protocol)
* IMAP (Internet Message Access Protocol)
## Development and testing tools
Operating system: Debian 9 64bit

No-ip

Thuderbird application
* Packages:
* Postfix
* Spamassassin
* Letsencrypt
* Bsd-mailx
* Procmail
* dovecot-imapd, dovecot-pop3d, dovecot-lmtpd

## Project results
Mail server with domain: wtmail.hopto.org

Automated script to install an encrypted mail server with a spam tray and also accept the three operating modes:
- Online mode: direct access to emails
- Offline mode: synchronize the tray by taking emails from the mail server
- Disconnected mode: allow users to keep local copies of emails

## Step 1
1. Ask for the dynamic ip domain in No-ip (https://www.noip.com/)
2. Configure the DNS record update in No-ip
3. Download and demonize the noip2 script to start at system boot

        wget https://www.noip.com/client/linux/noip-duc-linux.tar.gz
        tar -xf noip-duc-linux.tar.gz
        cd noip-2.1.9-1/
        make
        make install
        cp debian.noip2.sh /etc/init.d/debian.noip2.sh 
        ln -s /etc/init.d/debian.noip2.sh /etc/rc0.d/K01debian.noip2.sh
        ln -s /etc/init.d/debian.noip2.sh /etc/rc1.d/K01debian.noip2.sh  
        ln -s /etc/init.d/debian.noip2.sh /etc/rc2.d/K01debian.noip2.sh  
        ln -s /etc/init.d/debian.noip2.sh /etc/rc3.d/K01debian.noip2.sh  
        ln -s /etc/init.d/debian.noip2.sh /etc/rc4.d/K01debian.noip2.sh
        ln -s /etc/init.d/debian.noip2.sh /etc/rc5.d/S01debian.noip2.sh
        ln -s /etc/init.d/debian.noip2.sh /etc/rc6.d/K01debian.noip2.sh  
        chmod 755 debian.noip2.sh
        systemctl start postfix
        systemctl enable postfix

## Step 2
1. Set private ip for the mail server
2. Open NAT port to receive requests

## Step 3
1. Installl postfix: 

        apt-get install postfix

## Step 4
1. Install procmail: 

        apt-get install procmail
    
2. Configure Postfix in /etc/postfix/main.cf

         echo "myhostname = $host_name" >> /etc/postfix/main.cf
         echo "mydomain = $host_name" >> /etc/postfix/main.cf
         echo 'myorigin = $mydomain' >> /etc/postfix/main.cf
         echo 'mydestination= $myhostname, localhost.$mydomain,$mydomain,mail.$mydomain,www.$mydomain' >> /etc/postfix/main.cf
         echo 'mail_spool_directory = /var/spool/mail' >> /etc/postfix/main.cf
         echo 'mynetworks = 127.0.0.0/8, 192.168.1.0/24' >> /etc/postfix/main.cf
         echo 'inet_protocols = ipv4' >> /etc/postfix/main.cf
         systemctl reload postfix
         postfix check

## Step 5
1. Implement the SPAM tray using "spamassassin"

         apt-get install spamassassin
         systemctl start spamassassin
         systemctl enable spamassassin
         
 2. Integrate in postfix and restart it
 
        echo ':0 hbfw' >> /etc/procmailrc
        echo '| /usr/bin/spamc' >> /etc/procmailrc
        echo 'mailbox_command = /usr/bin/procmail' >> /etc/postfix/main.cf
        systemctl restart postfix
         
## Step 6
1. Secure the SMTP connection through TLS (Generating the certificate and the key using openssl)

        cd /etc/postfix
        openssl genrsa -des3 -out mail.key
        openssl req -new -key mail.key -out mail.csr
        cp mail.key mail.key.original
        openssl rsa -in mail.key.original -out mail_secure.key
        openssl x509 -req -days 365 -in mail_secure.csr -signkey mail_secure.key -out mail_secure.crt
        
2. Add the TLS options to the Postfix configuration file /etc/postfix/main.cf

        cp mail_secure.crt /etc/postfix/
        cp mail_secure.key /etc/postfix/
        echo 'smtpd_use_tls = yes' >> /etc/postfix/main.cf
        echo 'smtpd_tls_cert_file = /etc/postfix/mail_secure.crt' >> /etc/postfix/main.cf
        echo 'smtpd_tls_key_file = /etc/postfix/mail_secure.key' >> /etc/postfix/main.cf
        echo 'smtp_tls_security_level = may' >> /etc/postfix/main.cf
        systemctl restart postfix
        
3. Encrypt traffic using the free SSL certificate provider (Let's Encrypt)

        letsencrypt certonly --standalone -d "$host_name"
        postconf -e "mtpd_tls_cert_file = /etc/letsencrypt/live/$host_name/fullchain.pem"
        postconf -e "smtpd_tls_key_file = /etc/letsencrypt/live/$host_name/privkey.pem"
        systemctl restart postfix

## Step 7
1. Install Dovecot to integrate POP3 and IMAP
        
        apt-get install dovecot-imapd dovecot-pop3d dovecot-lmtpd
        
2. Configure Dovecot in /etc/dovecot/conf.d/dovecot.conf

        systemctl start dovecot
        systemctl enable dovecot
        echo "protocols =  imap pop3 lmtp" >> /etc/dovecot/dovecot.conf
        echo "listen = *, ::" >> /etc/dovecot/dovecot.conf
        echo "userdb {" >> /etc/dovecot/dovecot.conf
        echo "driver = passwd" >> /etc/dovecot/dovecot.conf
        echo "}" >> /etc/dovecot/dovecot.conf
        echo "passdb {" >> /etc/dovecot/dovecot.conf
        echo "driver = passwd" >> /etc/dovecot/dovecot.conf
        echo "}" >> /etc/dovecot/dovecot.conf
        
3. Modify generic Dovecot SSL certificates to Let's Encrypt certificates

        echo "mail_location = mbox:~/mail:INBOX=/var/mail/%u" >> /etc/dovecot/conf.d/10-main.conf
        echo "ssl_cert = </etc/letsencrypt/live/$host_name/fullchain.pem" >>  /etc/dovecot/conf.d/10-ssl.conf
        echo "ssl_key = </etc/letsencrypt/live/$host_name/privkey.pem" >> /etc/dovecot/conf.d/10-ssl.conf
        echo "ssl = yes" >> /etc/dovecot/conf.d/10-ssl.conf

## Step 8
1. Enable MX in No-ip

## Step 9
1. Text your email server
