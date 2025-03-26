FROM almalinux:8  
MAINTAINER deenamail2004@gmail.com

# Install necessary packages
RUN dnf install -y httpd zip unzip curl && \
    dnf clean all

# Set working directory
WORKDIR /var/www/html/

# Download and extract template
RUN curl -o football-card.zip -L "https://www.free-css.com/assets/files/free-css-templates/download/page36/football-card.zip" && \
    unzip football-card.zip && \
    cp -rvf football-card/* . && \
    rm -rf football-card football-card.zip

# Expose HTTP port
EXPOSE 80

# Start Apache in the foreground
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]

