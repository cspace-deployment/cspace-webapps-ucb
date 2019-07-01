__author__ = 'jblowe'

from django.urls import include, path
from toolbox import views

urlpatterns = [
    path('', views.toolbox, name='toolbox'),
    path('json/', views.jsonrequest, name='jsonrequest'),
    path('(P<appname>[\w\-]+)/?', views.tool, name='toolbox'),
]
