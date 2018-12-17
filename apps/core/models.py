from django.db import models


class BaseModel(models.Model):
    created = models.DateTimeField(auto_now_add=True)
    modified = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True

    @classmethod
    def properties_helptext(cls, additional_data=None):
        """
        Returns docstring for each property as help_text
        intended to be used to document views/serializers
        use additional_data to add/override values in the result
        """
        result = {
            prop: {"help_text": getattr(cls, prop).__doc__}
            for prop in dir(cls)
            if isinstance(getattr(cls, prop), property)
        }
        if additional_data:
            result.update(additional_data)


return result
