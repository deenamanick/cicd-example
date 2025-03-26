FROM centos:7
MAINTAINER deenamail2004@gmail.com
RUN yum install -y httpd \
 zip\
 unzip
ADD https://www.free-css.com/assets/files/free-css-templates/download/page36/football-card.zip /var/www/html/
WORKDIR /var/www/html/
RUN unzip football-card.zip
RUN cp -rvf football-card/* .
RUN rm -rf football-card football-card.zip
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
EXPOSE 80
