#!/bin/bash
host_name = "wtmail.hopto.org"
apt-get install gcc make postfix spamassassin letsencrypt bsd-mailx procmail dovecot-imapd dovecot-pop3d dovecot-lmtpd
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
echo "myhostname = $host_name" >> /etc/postfix/main.cf
echo "mydomain = $host_name" >> /etc/postfix/main.cf
echo 'myorigin = $mydomain' >> /etc/postfix/main.cf
echo 'mydestination= $myhostname, localhost.$mydomain,$mydomain,mail.$mydomain,www.$mydomain'
echo 'mail_spool_directory = /var/spool/mail'
echo 'mynetworks = 127.0.0.0/8, 192.168.1.0/24'
echo 'inet_protocols = ipv4'
systemctl reload postfix
postfix check
systemctl start spamassassin
systemctl enable spamassassin
echo ':0 hbfw' >> /etc/procmailrc
echo '| /usr/bin/spamc' >> /etc/procmailrc
echo 'mailbox_command = /usr/bin/procmail' >> /etc/postfix/main.cf
systemctl restart postfix
cd /etc/postfix
openssl genrsa -des3 -out mail.key
openssl req -new -key mail.key -out mail.csr
cp mail.key mail.key.original
openssl rsa -in mail.key.original -out mail_secure.key
openssl x509 -req -days 365 -in mail_secure.csr -signkey mail_secure.key -out mail_secure.crt
cp mail_secure.crt /etc/postfix/
cp mail_secure.key /etc/postfix/
echo 'smtpd_use_tls = yes' >> /etc/postfix/main.cf
echo 'smtpd_tls_cert_file = /etc/postfix/mail_secure.crt' >> /etc/postfix/main.cf
echo 'smtpd_tls_key_file = /etc/postfix/mail_secure.key' >> /etc/postfix/main.cf
echo 'smtp_tls_security_level = may' >> /etc/postfix/main.cf
systemctl restart postfix
letsencrypt certonly --standalone -d "$host_name"
postconf -e "mtpd_tls_cert_file = /etc/letsencrypt/live/$host_name/fullchain.pem"
postconf -e "smtpd_tls_key_file = /etc/letsencrypt/live/$host_name/privkey.pem"
systemctl restart postfix
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
echo "mail_location = mbox:~/mail:INBOX=/var/mail/%u" >> /etc/dovecot/conf.d/10-main.conf
echo "ssl_cert = </etc/letsencrypt/live/$host_name/fullchain.pem" >>  /etc/dovecot/conf.d/10-ssl.conf
echo "ssl_key = </etc/letsencrypt/live/$host_name/privkey.pem" >> /etc/dovecot/conf.d/10-ssl.conf
echo "ssl = yes" >> /etc/dovecot/conf.d/10-ssl.conf

