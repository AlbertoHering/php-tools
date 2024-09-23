# Use the official PHP 7.4 CLI image as the base
FROM php:7.4-cli

# Install dependencies required by PHPStan, PHP_CodeSniffer, and PHP-CS-Fixer
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    && apt-get clean

# Install Composer (needed to install PHPStan)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install PHPStan via Composer
RUN composer global require phpstan/phpstan

# Add Composer global bin to the PATH
ENV PATH="/root/.composer/vendor/bin:${PATH}"

# Install PHP_CodeSniffer
RUN curl -OL https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar \
    && chmod +x phpcs.phar \
    && mv phpcs.phar /usr/local/bin/phpcs

# Install PHP_CodeSniffer Beautifier
RUN curl -OL https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar \
    && chmod +x phpcbf.phar \
    && mv phpcbf.phar /usr/local/bin/phpcbf

# Install PHP-CS-Fixer
RUN curl -L https://github.com/FriendsOfPHP/PHP-CS-Fixer/releases/latest/download/php-cs-fixer.phar -o php-cs-fixer \
    && chmod +x php-cs-fixer \
    && mv php-cs-fixer /usr/local/bin/php-cs-fixer

    # Install PHP-CS-Fixer with a specific version
RUN curl -L https://github.com/FriendsOfPHP/PHP-CS-Fixer/releases/download/v3.12.0/php-cs-fixer.phar -o php-cs-fixer \
    && chmod +x php-cs-fixer \
    && mv php-cs-fixer /usr/local/bin/php-cs-fixer

# Install PHP-CS-Fixer via Composer
RUN composer global require friendsofphp/php-cs-fixer

# Set the working directory
WORKDIR /app

# Default command to list installed tools
CMD ["phpstan", "--version"]
