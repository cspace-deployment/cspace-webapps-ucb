"""
CineFiles webapps
"""
from django.urls import include, path
from django.contrib import admin
from django.contrib.auth import views

#
# Initialize our web site - things like our AuthN backend need to be initialized.
#
from cspace_django_site.main import cspace_django_site

cspace_django_site.initialize()

urlpatterns = [
    # these are django builtin webapps
    path('admin/', admin.site.urls),
    path('accounts/login/', views.LoginView.as_view(), name='login'),
    path('accounts/logout/', views.LogoutView.as_view(), name='logout'),
    path('', include('landing.urls')),
    path('landing/', include('landing.urls'), name='landing'),

    # these are 2 "helper" apps, a generic 'hello world' and a proxy to cspace services
    # path('hello', 'hello.views.home', name='home'),
    # path('service/', include('service.urls')),
    # these are "internal webapps", used by other webapps -- not user-facing
    path('suggestpostgres/', include('suggestpostgres.urls'), name='suggestpostgres'),
    path('suggestsolr/', include('suggestsolr.urls'), name='suggestsolr'),
    path('suggest/', include('suggest.urls'), name='suggest'),
    path('imageserver/', include('imageserver.urls'), name='imageserver'),

    # these are user-facing (i.e. present a UI to the caller)
    # path('asura/', include('asura.urls'), name='asura'),
    # path('cinestats/', include('cinestats.urls'), name='cinestats'),
    path('grouper/', include('grouper.urls'), name='grouper'),
    # path('imagebrowser/', include('imagebrowser.urls'), name='imagebrowser'),
    # path('imaginator/', include('imaginator.urls'), name='imaginator'),
    # path('internal/', include('internal.urls'), name='internal'),
    # path('ireports/', include('ireports.urls'), name='ireports'),
    path('search/', include('search.urls'), name='search'),
    ##path('simplesearch/', include('simplesearch.urls'), name='simplesearch'),
    # path('toolbox/', include('toolbox.urls'), name='toolbox'),
    path('uploadmedia/', include('uploadmedia.urls'), name='uploadmedia'),
    # path('uploadtricoder/', include('uploadtricoder.urls'), name='uploadtricoder'),

    # these two paths are special: they are used to create permalinks for objects and media
    # path('media/', include('permalinks.urls'), name='permalinks'),
    # path('object/', include('permalinks.urls'), name='permalinks'),
]
