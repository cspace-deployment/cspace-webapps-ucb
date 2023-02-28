from django.contrib import admin

from .models import Transaction


class TransactionAdmin(admin.ModelAdmin):
    list_display = ['accession_number', 'job', 'status']  # show in admin
    search_fields = ['accession_number', 'job']  # search

admin.site.register(Transaction, TransactionAdmin)
