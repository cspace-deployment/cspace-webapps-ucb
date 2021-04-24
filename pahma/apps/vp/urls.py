__author__ = 'jblowe'

from django.urls import include, path
from vp import views

urlpatterns = [
    path('', views.index, name='locations'),
]
