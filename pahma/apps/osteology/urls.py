__author__ = 'amywieliczka, jblowe'

from django.urls import include, path
from osteology import views

urlpatterns = [
    path('', views.direct, name='direct'),
    path('skeleton/', views.skeleton, name='skeleton'),
    path('search/', views.search, name='search'),
    path('results/', views.retrieveResults, name='retrieveResults'),
]
