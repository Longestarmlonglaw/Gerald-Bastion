import type { BooleanLike } from 'common/react';
import type { ReactNode } from 'react';
import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';
import { type Objective, ObjectivePrintout } from './common/Objectives';

const ARCFIEND_YELLOW = '#ffe94d';

type Power = {
  path: string;
  name: string;
  desc: string;
  tier: number;
  passive: BooleanLike;
  owned: BooleanLike;
  level: number;
  max_level: number;
  upgrade_descriptions: string[];
  // Null once a power is fully upgraded
  cost: number | null;
  // Not enough unique minds drained yet
  locked: BooleanLike;
  minds_needed: number;
  can_afford: BooleanLike;
};

type Info = {
  antag_name: string;
  power: number;
  power_cap: number;
  total_drained: number;
  minds_drained: number;
  objectives: Objective[];
  powers: Power[];
  tier_requirements: number[];
};

export const AntagInfoArcfiend = () => {
  const { data } = useBackend<Info>();
  const { power, power_cap, total_drained, minds_drained, tier_requirements } =
    data;
  const [currentTab, setTab] = useLocalState('arcfiendTab', 0);
  // The number of minds the next locked tier needs, if there is one
  const nextGoal = tier_requirements.find((needed) => needed > minds_drained);

  return (
    <Window width={720} height={780}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Section>
              <LabeledList>
                <LabeledList.Item label="Power">
                  <ProgressBar
                    value={power}
                    minValue={0}
                    maxValue={power_cap}
                    color={ARCFIEND_YELLOW}
                  >
                    {power} / {power_cap}
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item label="Total drained">
                  {total_drained}
                </LabeledList.Item>
                <LabeledList.Item label="Minds drained">
                  {minds_drained}
                  {nextGoal !== undefined ? (
                    <Box as="span" color="average" ml={1}>
                      - hunt {nextGoal - minds_drained} more player
                      {nextGoal - minds_drained === 1 ? '' : 's'} to unlock the
                      next tier
                    </Box>
                  ) : (
                    <Box as="span" color="good" ml={1}>
                      - every tier unlocked
                    </Box>
                  )}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab
                icon="info"
                selected={currentTab === 0}
                onClick={() => setTab(0)}
              >
                Information
              </Tabs.Tab>
              <Tabs.Tab
                icon="book"
                selected={currentTab === 1}
                onClick={() => setTab(1)}
              >
                Guide
              </Tabs.Tab>
              <Tabs.Tab
                icon="arrow-up"
                selected={currentTab === 2}
                onClick={() => setTab(2)}
              >
                Upgrades
              </Tabs.Tab>
              <Tabs.Tab
                icon="bolt"
                selected={currentTab === 3}
                onClick={() => setTab(3)}
              >
                New Powers
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            {(currentTab === 0 && <InformationTab />) ||
              (currentTab === 1 && <GuideTab />) ||
              (currentTab === 2 && <UpgradesTab />) || <NewPowersTab />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const InformationTab = () => {
  const { data } = useBackend<Info>();
  const { antag_name, objectives } = data;
  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section>
          <Box color={ARCFIEND_YELLOW} fontSize="20px" bold>
            You are the {antag_name}!
          </Box>
          <Box mt={1}>
            Nanites rewrote your body to run on electricity. You can feel every
            cable, APC and machine on the station, and you can take their power.
            Electricity can't hurt you. It only feeds you.
          </Box>
          <Box mt={1}>
            You're still flesh, though. Bullets, blades and fire hurt you like
            anyone else, and an outside EMP will sear you and scatter your
            stored power. Be careful who sees you feeding.
          </Box>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section fill scrollable>
          <ObjectivePrintout objectives={objectives} />
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const GuideTab = () => {
  const { data } = useBackend<Info>();
  const { tier_requirements, minds_drained } = data;
  return (
    <Section fill scrollable title="How to play an Arcfiend">
      <NoticeBox danger>
        Power alone won't get you everything. Tier 2 needs{' '}
        {tier_requirements[1]} different player
        {tier_requirements[1] === 1 ? '' : 's'} drained, and tier 3 needs{' '}
        {tier_requirements[2]}. You've drained {minds_drained} so far. Machines
        never count, only living people with a player behind them.
      </NoticeBox>
      <Stack vertical>
        <GuideSection title="Power">
          Power pays for everything: using your powers, learning them and
          upgrading them. You get it by sapping APCs, SMES units, cables and
          machines, but people and cyborgs give far more. Sapping is loud and
          bright, and it also feeds you, so you never need to eat. It won't make
          you fat, or overcharge you if you're an ethereal. You can only hold so
          much, and outside EMPs will scatter some of it.
        </GuideSection>
        <GuideSection title="Using powers">
          Powers you aim put a glowing hand in your hand while they're ready.
          Click your target to use them, or use the power again or press the
          drop key to cancel. Weapons and tools you grow can be put away with
          the drop key too.
        </GuideSection>
        <GuideSection title="Defenses and weaknesses">
          You can't be shocked, and nothing can give you a heart attack. You
          still need your heart though, and if it's damaged until it fails, it
          stops. You take a little less burn and stamina damage than most
          people, but nothing protects you from brute damage. What you
          carry or have inside you, like cybernetics and energy guns, is safe
          from EMPs. You aren't.
        </GuideSection>
        <GuideSection title="Senses">
          You know what every wire does on any machine, bombs included. You have
          a built-in diagnostic display, and you can see hidden cables nearby.
        </GuideSection>
        <GuideSection title="Getting stronger">
          Spend power in the Upgrades tab to improve your powers, and in the New
          Powers tab to learn more. The first level of a power only costs power.
          Higher tiers and upgrade levels need players drained.
        </GuideSection>
        <GuideSection title="Hunting players">
          To count, a player has to be alive and have someone controlling them,
          and you have to drain a few seconds' worth from them. Each person only
          counts once. Corpses, mindless bodies, cyborgs with nobody in them and
          machines don't count. Draining a person hurts them and gives you a lot
          of power, so expect to be noticed. Upgrade level 2 needs{' '}
          {tier_requirements[1]} player{tier_requirements[1] === 1 ? '' : 's'},
          and level 3 needs {tier_requirements[2]}.
        </GuideSection>
        <GuideSection title="Objectives">
          Drain the amount of power you were given, finish your other
          objectives, and escape on the shuttle alive and out of custody.
        </GuideSection>
      </Stack>
    </Section>
  );
};

const GuideSection = (props: { title: string; children: ReactNode }) => {
  return (
    <Stack.Item>
      <Box color={ARCFIEND_YELLOW} bold>
        {props.title}
      </Box>
      <Box>{props.children}</Box>
    </Stack.Item>
  );
};

const UpgradesTab = () => {
  const { data } = useBackend<Info>();
  const owned = data.powers.filter((entry) => !!entry.owned);
  return (
    <Section fill scrollable title="Upgrade your powers">
      {owned.length === 0 ? (
        <Box color="label">You have no powers to upgrade.</Box>
      ) : (
        <Stack vertical>
          {owned.map((entry) => (
            <Stack.Item key={entry.path}>
              <PowerEntry power={entry} />
            </Stack.Item>
          ))}
        </Stack>
      )}
    </Section>
  );
};

const NewPowersTab = () => {
  const { data } = useBackend<Info>();
  const { tier_requirements } = data;
  const available = data.powers.filter((entry) => !entry.owned);
  return (
    <Section
      fill
      scrollable
      title="Learn new powers"
      buttons={
        <Box color="label">
          Tier 2 needs {tier_requirements[1]} mind
          {tier_requirements[1] === 1 ? '' : 's'}, tier 3 needs{' '}
          {tier_requirements[2]}.
        </Box>
      }
    >
      {available.length === 0 ? (
        <Box color="label">There is nothing left for you to learn yet.</Box>
      ) : (
        <Stack vertical>
          {available.map((entry) => (
            <Stack.Item key={entry.path}>
              <PowerEntry power={entry} />
            </Stack.Item>
          ))}
        </Stack>
      )}
    </Section>
  );
};

const PowerEntry = (props: { power: Power }) => {
  const { act, data } = useBackend<Info>();
  const { power } = props;
  const mindsShort = Math.max(power.minds_needed - data.minds_drained, 0);
  const fullyUpgraded = !!power.owned && power.cost === null;
  const nextUpgrade = power.upgrade_descriptions[power.level - 1];

  const buttonText = power.owned
    ? `Upgrade (${power.cost})`
    : `Learn (${power.cost})`;
  const action = power.owned ? 'upgrade' : 'purchase';

  let tooltip: string | undefined;
  if (power.locked) {
    tooltip = `You need to have drained ${power.minds_needed} mind${power.minds_needed === 1 ? '' : 's'} first.`;
  } else if (!power.can_afford) {
    tooltip = 'You need more power.';
  }

  return (
    <Section
      title={
        <>
          {power.name}
          <Box as="span" color="label" ml={1} fontSize="12px">
            Tier {power.tier}
            {!!power.passive && ' - Passive'}
            {!!power.owned && ` - Level ${power.level}/${power.max_level}`}
          </Box>
        </>
      }
      buttons={
        fullyUpgraded ? (
          <Box color="good" bold>
            Fully upgraded
          </Box>
        ) : (
          <Button
            disabled={!!power.locked || !power.can_afford}
            tooltip={tooltip}
            onClick={() => act(action, { path: power.path })}
          >
            {buttonText}
          </Button>
        )
      }
    >
      <Box>{power.desc}</Box>
      {!!power.locked && (
        <Box mt={1} color="bad" bold>
          Locked: hunt and drain {mindsShort} more different player
          {mindsShort === 1 ? '' : 's'} first ({power.minds_needed} needed in
          total).
        </Box>
      )}
      {!!power.owned && !fullyUpgraded && !!nextUpgrade && (
        <Box mt={1} color={ARCFIEND_YELLOW}>
          Next level: {nextUpgrade}
        </Box>
      )}
    </Section>
  );
};
