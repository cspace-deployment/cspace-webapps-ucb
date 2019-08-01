__author__ = 'jblowe'

from django.urls import include, path
from uploadtricoder import views

urlpatterns = [
    path('', views.uploadfiles),
    path('tri_uploadfiles', views.uploadfiles, name='uploadfiles'),
    path('tri_checkfilename', views.checkfilename, name='checkfilename'),
    path('tri_showqueue', views.showqueue, name='showqueue'),
    path('tri_showresults', views.showresults, name='showresults'),
]
