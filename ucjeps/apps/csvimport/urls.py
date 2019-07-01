__author__ = 'jblowe'

from django.urls import include, path
from csvimport import views

urlpatterns = [
    path('', views.upload_file),
    path('uploadfile', views.upload_file, name='uploadfile'),
    path('showqueue', views.showqueue, name='showqueue'),
    path('downloadresults/<filename>', views.downloadresults, name='downloadresults'),
    path('showresults/<filename>', views.showresults, name='showresults'),
    path('deletejob/<jobname>', views.deletejob, name='deletejob'),
    path('nextstep/<step>/<filename>', views.nextstep, name='nextstep'),
    path('showcsvconfig', views.show_csv_config, name='showcsvconfig'),
]
