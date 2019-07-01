__author__ = 'jblowe'

from django.urls import include, path
from workflow import views

urlpatterns = [
    path('', views.workflow, name='index'),
    path('(P<page>[\w\-\.]+)?', views.workflow, name='index')
]
