from django.urls import include, path
from merritt_archive import views

urlpatterns = [
    path('', views.index, name='merritt_archive'),
    #path(r'add/', views.add_transaction),
    path(r'callback/', views.callback),
    path(r'search/', views.index),
    path(r'jobinfo/<str:job>', views.index),
    #path(r'detail/<int:pk>/', views.archive_detail),
]