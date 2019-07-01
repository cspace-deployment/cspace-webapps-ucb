__author__ = 'jblowe, rjaffe'

from django.urls import include, path
from eloan import views

urlpatterns = [
    path('', views.eloan, name='eloan'),
]
