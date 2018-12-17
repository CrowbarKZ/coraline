from decimal import Decimal

from django.db import models

from apps.core.models import BaseModel


class Invoice(BaseModel):

    number = models.CharField(max_length=10, unique=True)
    date_issue = models.DateField()
    date_due = models.DateField()
    vat_percent = models.DecimalField(blank=True, default=Decimal(0))
