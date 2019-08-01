__author__ = 'jblowe'

from django.urls import include, path
from x3dviewer import views

urlpatterns = [
    path('', views.x3dviewer, name='x3dviewer')
]
