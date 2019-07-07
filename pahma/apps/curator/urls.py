__author__ = 'jblowe'

from django.urls import include, path
from curator import views

urlpatterns = [
    path('', views.curator, name='curator'),
]