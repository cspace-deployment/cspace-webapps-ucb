from django.db import models

# STATUSES = [(s, s) for s in 'new,ok,deferred,queued,archived,tidied'.split(',')]

class Transaction(models.Model):
    accession_number = models.TextField()
    image_filename = models.TextField()
    status = models.TextField()
    #status = models.CharField(choices=STATUSES, default='start', max_length=10000)
    job = models.TextField()
    transaction_date = models.DateTimeField(auto_now_add=True)
    transaction_detail = models.TextField()

    class Meta:
        verbose_name = "Transaction"
        verbose_name_plural = "Transactions"
        ordering = ('transaction_date',)

    def __str__(self):
        return self.accession_number