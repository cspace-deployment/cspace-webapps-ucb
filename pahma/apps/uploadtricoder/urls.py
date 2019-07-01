__author__ = 'jblowe'

from django.urls import include, path
from uploadtricoder import views

urlpatterns = [
    path('', views.uploadfiles),
    path('uploadfiles', views.uploadfiles, name='uploadfiles'),
    path('rest/(P<action>[\w\-\.]+)', views.rest, name='rest'),
    path('checkfilename', views.checkfilename, name='checkfilename'),
    path('showqueue', views.showqueue, name='showqueue'),
    path('showresults', views.showresults, name='showresults'),
    # path(''createtricoder', views.createtricoder, name='createtricoder'),
]
