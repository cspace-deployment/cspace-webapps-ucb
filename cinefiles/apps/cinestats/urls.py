from django.urls import include, path

from cinestats import views

urlpatterns = [
    path('', views.cinestats, name='cinestats')
]
