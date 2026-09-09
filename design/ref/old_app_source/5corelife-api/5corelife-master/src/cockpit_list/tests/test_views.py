from rest_framework import status

from cockpit_list.models import CockpitList
from cockpit_list.models import CockpitListBase
from config.testing.api_test_base import ApiTestBase


class TestCockPitList(ApiTestBase):
    """Get CockpitList"""

    def test_cockpitlist(self):
        response = self.client.get("/cockpit-list/")

        self.assertEqual(status.HTTP_200_OK, response.status_code)

    """Get str from models"""

    def test_models_return_str(self):
        cockpit_list_base = CockpitListBase.objects.get(name="Goals").__str__()
        cockpit_list = CockpitList.objects.get(name="Goals").__str__()
        result_expected = "Goals"

        self.assertEqual(result_expected, cockpit_list_base)
        self.assertEqual(result_expected, cockpit_list)
