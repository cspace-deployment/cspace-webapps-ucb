# these are the webapps available for Cinefiles

INSTALLED_APPS = (
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.sites',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Uncomment the next line to enable the admin:
    'django.contrib.admin',
    # Uncomment the next line to enable admin documentation:
    # 'django.contrib.admindocs',
    # 'demo' apps -- uncomment for debugging or demo
    # 'hello',
    # 'service',
    # 'service' apps: no UI
    'common',
    'suggest',
    'suggestpostgres',
    'suggestsolr',
    # 'cinestats',
    # 'standard' apps
    # 'asura',
    # 'imagebrowser',
    'grouper',
    'imageserver',
    # 'imaginator',
    # 'internal',
    # 'ireports',
    'landing',
    'permalinks',
    'search',
    # 'toolbox',
    # 'simplesearch',
    'uploadmedia',
    # 'uploadtricoder',
)
