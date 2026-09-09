from django.contrib.admin.views.decorators import staff_member_required
from django.shortcuts import render


@staff_member_required
def view_report(request):
    context = {}
    return render(request, 'admin/reports.html', context)
