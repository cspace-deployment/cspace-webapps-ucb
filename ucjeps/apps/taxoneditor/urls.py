__author__ = 'jblowe'

from django.urls import include, path
from taxoneditor import views

urlpatterns = [
    path('', views.taxoneditor, name='index'),
    path('create/', views.create_taxon, name='create_taxon'),
]
