__author__ = 'jblowe'

from django.urls import include, path
from uploadtricoder import views

urlpatterns = [
    path('', views.uploadfiles),
    path('tri_uploadfiles', views.uploadfiles, name='tri_uploadfiles'),
    path('tri_checkfilename', views.checkfilename, name='tri_checkfilename'),
    path('tri_showqueue', views.showqueue, name='tri_showqueue'),
    path('tri_showresults', views.showresults, name='tri_showresults'),
]
