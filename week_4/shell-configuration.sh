# File: /etc/profile
# Runs on login for all shell types

# Set default PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Set language (Spanish)
export LANG=es_ES.UTF-8

# Set timezone
export TZ=Europe/Madrid

# Set default editor
export EDITOR=nano

# Set default pager
export PAGER=less

# Run scripts in /etc/profile.d/
for script in /etc/profile.d/:.sh; do
    source "$script"
done