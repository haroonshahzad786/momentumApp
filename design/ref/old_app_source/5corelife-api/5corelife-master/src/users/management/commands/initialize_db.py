from django.core.management.base import BaseCommand

from bonus.models import Bonus
from bonus.strings import (
    INCREASE_CORE_POWER_DAY,
    INCREASE_MOMENTUM_JOURNEY,
    SKIP_CHECK_IN,
)
from cockpit_list.models import CockpitListBase
from destinations.models import Destination
from improvements.models import Improvement
from mission.models import Mission
from quests.models import Quest
from trophy.models import Trophy


class Command(BaseCommand):
    help = "Initialize the DB"

    def add_arguments(self, parser):
        parser.add_argument(
            '--clean',
            action='store_true',
            help='Remove the existing objects prior to create them.',
        )

    def handle(self, *args, **options):
        if options['clean']:
            Destination.objects.all().delete()
            Trophy.objects.all().delete()
            Improvement.objects.all().delete()
            Bonus.objects.all().delete()
        moon = Destination(destination='The Moon', length=2, momentum_required=15, cores=2, core_cap=50, index=2)
        mars = Destination(destination='Mars', length=3, momentum_required=20, cores=3, core_cap=50, index=3)
        saturn = Destination(destination='Saturn', length=8, momentum_required=40, cores=5, core_cap=60, index=7)
        pluto = Destination(destination='Pluto', length=18, momentum_required=75, cores=5, core_cap=80, index=14)
        jupiter = Destination(destination='Jupiter', length=6, momentum_required=30, cores=5, core_cap=60, index=5)
        titan = Destination(destination='Titan', length=9, momentum_required=45, cores=5, core_cap=60, index=8)
        neptune = Destination(destination='Neptune', length=14, momentum_required=70, cores=5, core_cap=70, index=12)
        eris = Destination(destination='Eris', length=20, momentum_required=75, cores=5, core_cap=100, index=15)
        Destination.objects.bulk_create(
            [
                Destination(
                    destination='Space Station 1', length=1, momentum_required=10, cores=1, core_cap=50, index=1
                ),
                moon,
                mars,
                Destination(destination='Ceres', length=4, momentum_required=25, cores=4, core_cap=50, index=4),
                jupiter,
                Destination(destination='Europa', length=7, momentum_required=35, cores=5, core_cap=60, index=6),
                saturn,
                titan,
                Destination(
                    destination='Space Station 2', length=10, momentum_required=50, cores=5, core_cap=60, index=9
                ),
                Destination(destination='Uranus', length=11, momentum_required=55, cores=5, core_cap=70, index=10),
                Destination(
                    destination='Space Station 3', length=12, momentum_required=65, cores=5, core_cap=70, index=11
                ),
                neptune,
                Destination(destination='Triton', length=16, momentum_required=75, cores=5, core_cap=70, index=13),
                pluto,
                eris,
                Destination(destination='Endless', length=999, momentum_required=80, cores=5, core_cap=100, index=16),
            ]
        )

        Trophy.objects.bulk_create(
            [
                Trophy(name='7-day Streak', quantity_days=7),
                Trophy(name='14-day Streak', quantity_days=14),
                Trophy(name='21-day Streak', quantity_days=21),
                Trophy(name='50 Momentum', quantity_momentum=50),
                Trophy(name='75 Momentum', quantity_momentum=75),
                Trophy(name='100 Momentum', quantity_momentum=100),
                Trophy(name='Moon', reach_destination=moon),
                Trophy(name='Mars', reach_destination=mars),
                Trophy(name='Saturn', reach_destination=saturn),
                Trophy(name='Pluto', reach_destination=pluto),
                Trophy(name='1 Habit complete', quantity_habits=1),
                Trophy(name='5 Habit complete', quantity_habits=5),
                Trophy(name='10 Habit complete', quantity_habits=10),
                Trophy(name='20 Habit complete', quantity_habits=20),
            ]
        )

        Improvement.objects.bulk_create(
            [
                Improvement(name='Common', cost=150, probability_reward=20, improvement_type='WINGS', order=1),
                Improvement(name='Uncommon', cost=300, probability_reward=15, improvement_type='WINGS', order=2),
                Improvement(name='Rare', cost=500, probability_reward=10, improvement_type='WINGS', order=3),
                Improvement(name='Very Rare', cost=1000, probability_reward=5, improvement_type='WINGS', order=4),
                Improvement(name='Epic', cost=5000, probability_reward=0, improvement_type='WINGS', order=5),
                Improvement(name='Rare', cost=250, probability_reward=15, improvement_type='THRUSTER', order=1),
                Improvement(name='Very Rare', cost=500, probability_reward=5, improvement_type='THRUSTER', order=2),
                Improvement(name='Epic', cost=2500, probability_reward=0, improvement_type='THRUSTER', order=3),
                Improvement(
                    name='Star Jump Engine', cost=10000, probability_reward=0, improvement_type='THRUSTER', order=6
                ),
                Improvement(
                    name='Base Armor', cost=0, probability_reward=0, improvement_type='ARMOR', default=True, order=0
                ),
                Improvement(
                    name='Base Thruster',
                    cost=0,
                    probability_reward=0,
                    improvement_type='THRUSTER',
                    default=True,
                    order=0,
                ),
                Improvement(
                    name='Base Wings', cost=0, probability_reward=0, improvement_type='WINGS', default=True, order=0
                ),
                Improvement(
                    name='Common', cost=0, probability_reward=0, destination=moon, improvement_type='ARMOR', order=1
                ),
                Improvement(
                    name='Uncommon',
                    cost=0,
                    probability_reward=0,
                    destination=jupiter,
                    improvement_type='ARMOR',
                    order=2,
                ),
                Improvement(
                    name='Rare', cost=0, probability_reward=0, destination=titan, improvement_type='ARMOR', order=3
                ),
                Improvement(
                    name='Very Rare',
                    cost=0,
                    probability_reward=0,
                    destination=neptune,
                    improvement_type='ARMOR',
                    order=4,
                ),
                Improvement(
                    name='Epic', cost=0, probability_reward=0, destination=eris, improvement_type='ARMOR', order=5
                ),
            ]
        )

        Bonus.objects.bulk_create(
            [
                Bonus(name=SKIP_CHECK_IN, cost=200, probability_reward=20),
                Bonus(name=INCREASE_MOMENTUM_JOURNEY, cost=5, probability_reward=5),
                Bonus(name=INCREASE_CORE_POWER_DAY, cost=200, probability_reward=20),
            ]
        )

        CockpitListBase.objects.bulk_create(
            [
                CockpitListBase(name='Back to the future', enabled=True, category='CORE'),
                CockpitListBase(name='One-Time-Actions', category='CORE'),
                CockpitListBase(name='Gratitude List', category='SORTABLE'),
                CockpitListBase(name='Daily Routine', category='SORTABLE'),
                CockpitListBase(name='Strengths', category='SORTABLE'),
                CockpitListBase(name='Passions', category='SORTABLE'),
                CockpitListBase(name='Weaknesses', category='SORTABLE'),
                CockpitListBase(name="Bold To-do's", category='SORTABLE'),
                CockpitListBase(name='Connections', category='SORTABLE'),
                CockpitListBase(name='Messes To Clean', category='SORTABLE'),
                CockpitListBase(name='Top People In My Life', category='CORE'),
                CockpitListBase(name='Top 5 Fears To Tackle', category='SORTABLE'),
                CockpitListBase(name='Stress/Dwelling Killer', category='SORTABLE'),
                CockpitListBase(name='Goals', category='CORE'),
            ]
        )

    Quest.objects.bulk_create(
        [
            Quest(
                name='Deliver fragile cargo',
                description='Maintain you active cores balance until you reach your destination (within 20% of each other)',
                code_name='fragile_cargo',
            ),
            Quest(
                name='Navigate safely through a challenging region',
                description='Don’t miss any check-ins during the current journey',
                code_name='navigate_safely',
            ),
        ]
    )

    Mission.objects.bulk_create(
        [
            Mission(
                name='Hostile encounter: Asteroids', description='Go outside of comfort zone!', code_name='comfort_zone'
            ),
            Mission(
                name='Hostile encounter: Aliens',
                description='Maintain balanced cores during the day (Active cores within 40% of each other on night check-in)',
                code_name='balanced_cores',
            ),
            Mission(
                name='Hostile encounter: Asteroids',
                description='Don’t let any core reduce its power from your previous check-in',
                code_name='previous_day',
            ),
            Mission(
                name='Hostile encounter: Aliens',
                description='Don’t score any core lower than 3',
                code_name='core_lower',
            ),
        ]
    )
