FROM almalinux:8
MAINTAINER deenamail2004@gmail.com

# Install required packages
RUN dnf install -y httpd unzip wget && dnf clean all

# Set working directory
WORKDIR /tmp

# Download and unzip the Story template
RUN wget --content-disposition --trust-server-names https://html5up.net/story/download/ -O html5up-story.zip && \
    unzip -q html5up-story.zip && \
    folder=$(unzip -Z -1 html5up-story.zip | grep '/' | cut -d/ -f1 | uniq | head -1) && \
    mv "$folder" /var/www/html/story && \
    rm -f html5up-story.zip

# Remove default Apache index page
RUN rm -f /var/www/html/index.html

# Expose HTTP port
EXPOSE 80

# Start Apache in foreground
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]

