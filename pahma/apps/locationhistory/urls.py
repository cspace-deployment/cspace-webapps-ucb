__author__ = 'jblowe'

from django.urls import include, path
from locationhistory import views

urlpatterns = [
    path('', views.locationhistory, name='locationhistory'),
    path('results', views.results, name='results'),
]
