__author__ = 'jblowe'

from django.urls import include, path
from csvimport import views

urlpatterns = [
    path('', views.upload_csv_file),
    path('uploadcsvfile', views.upload_csv_file, name='uploadcsvfile'),
    path('showcsvqueue', views.showqueue, name='showcsvqueue'),
    path('downloadcsvresults/<filename>', views.downloadresults, name='downloadcsvresults'),
    path('showcsvresults/<filename>', views.showresults, name='showcsvresults'),
    path('deletecsvjob/<jobname>', views.deletejob, name='deletecsvjob'),
    path('nextcsvstep/<step>/<filename>', views.nextstep, name='nextcsvstep'),
    path('showcsvconfig', views.show_csv_config, name='showcsvconfig'),
]
