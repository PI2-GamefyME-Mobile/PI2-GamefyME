from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('conquistas', '0004_add_dynamic_rules'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='conquista',
            name='periodo',
        ),
    ]
