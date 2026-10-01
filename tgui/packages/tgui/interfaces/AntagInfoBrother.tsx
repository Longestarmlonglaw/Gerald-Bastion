import type { BooleanLike } from 'common/react';
import type { ReactNode } from 'react';
import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Icon,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';
import { type Objective, ObjectivePrintout } from './common/Objectives';
import { PersonalCraftingContent } from './PersonalCrafting';

enum TAB {
  Objectives = 'objectives',
  Conspirators = 'conspirators',
  Crafting = 'crafting',
  Guide = 'guide',
}

type ConspiratorStatus =
  | 'conscious'
  | 'unconscious'
  | 'critical'
  | 'dead'
  | 'missing';

type Conspirator = {
  ref: string;
  name: string;
  rank: string | null;
  job: string | null;
  is_you: BooleanLike;
  status: ConspiratorStatus;
  health?: number;
  max_health?: number;
  brute?: number;
  burn?: number;
  toxin?: number;
  oxygen?: number;
};

type Data = {
  antag_name: string;
  objectives: Objective[];
  tab: TAB;
  rank: string;
  team_name: string | null;
  conspirators: Conspirator[];
  gear_chosen: string | null;
  gear_summoned: BooleanLike;
};

const STATUS_DISPLAY: Record<
  ConspiratorStatus,
  { label: string; color: string; icon: string }
> = {
  conscious: { label: 'Conscious', color: 'good', icon: 'heart-pulse' },
  unconscious: { label: 'Unconscious', color: 'average', icon: 'bed' },
  critical: { label: 'Critical', color: 'bad', icon: 'triangle-exclamation' },
  dead: { label: 'Dead', color: 'grey', icon: 'skull' },
  missing: { label: 'Body missing', color: 'grey', icon: 'question' },
};

export const AntagInfoBrother = (props) => {
  const { act, data } = useBackend<Data>();
  const { tab } = data;

  return (
    <Window width={760} height={720} theme="syndicate" title="Blood Bond">
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab
                icon="bullseye"
                selected={tab === TAB.Objectives}
                onClick={() => act('set_tab', { tab: TAB.Objectives })}
              >
                Objectives
              </Tabs.Tab>
              <Tabs.Tab
                icon="users"
                selected={tab === TAB.Conspirators}
                onClick={() => act('set_tab', { tab: TAB.Conspirators })}
              >
                Conspirators
              </Tabs.Tab>
              <Tabs.Tab
                icon="hammer"
                selected={tab === TAB.Crafting}
                onClick={() => act('set_tab', { tab: TAB.Crafting })}
              >
                Crafting
              </Tabs.Tab>
              <Tabs.Tab
                icon="book"
                selected={tab === TAB.Guide}
                onClick={() => act('set_tab', { tab: TAB.Guide })}
              >
                Guide
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          {/* minHeight 0 stops long tab content from stretching past the window, so it scrolls instead. */}
          <Stack.Item grow basis={0} style={{ minHeight: 0 }}>
            {tab === TAB.Objectives && <ObjectivesTab />}
            {tab === TAB.Conspirators && <ConspiratorsTab />}
            {tab === TAB.Crafting && <PersonalCraftingContent />}
            {tab === TAB.Guide && <GuideTab />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const ObjectivesTab = (props) => {
  const { data } = useBackend<Data>();
  const { rank, team_name, objectives, gear_chosen, gear_summoned } = data;

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section>
          <Box fontSize="22px" bold color="red">
            You are the {rank}!
          </Box>
          {!!team_name && (
            <Box mt={0.5} italic color="label">
              {team_name}
            </Box>
          )}
          <Box mt={1}>
            You and your brothers are bound by blood. Your objectives are
            shared, so you succeed or fail together. Check on each other in the{' '}
            <b>Conspirators</b> tab, and read the <b>Guide</b> tab if you're new
            to the bond.
          </Box>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section fill scrollable title="Shared Objectives">
          <ObjectivePrintout
            objectives={objectives}
            titleMessage="Your team must"
          />
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Team Gear">
          {gear_summoned ? (
            <Box color="good">
              <Icon name="box-open" mr={1} />
              Your team has already summoned {gear_chosen || 'its gear'}.
            </Box>
          ) : gear_chosen ? (
            <Box color="average">
              <Icon name="parachute-box" mr={1} />
              Your team chose <b>{gear_chosen}</b>. Use the Summon Gear action
              to drop-pod it to your location.
            </Box>
          ) : (
            <Box color="label">
              <Icon name="circle-question" mr={1} />
              Your team hasn't chosen its gear yet. Use the Choose Gear action
              to propose one.
            </Box>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const ConspiratorsTab = (props) => {
  const { data } = useBackend<Data>();
  const { conspirators = [] } = data;

  return (
    <Section fill scrollable title="Conspirators">
      {conspirators.length <= 1 && (
        <NoticeBox info>
          You have no brothers yet. Recruit someone with a flash to complete
          your bond.
        </NoticeBox>
      )}
      {conspirators.map((conspirator) => (
        <ConspiratorCard key={conspirator.ref} conspirator={conspirator} />
      ))}
    </Section>
  );
};

const ConspiratorCard = (props: { conspirator: Conspirator }) => {
  const { conspirator } = props;
  const status = STATUS_DISPLAY[conspirator.status];
  const hasBody = conspirator.status !== 'missing';
  const healthFraction =
    conspirator.status === 'dead' || !conspirator.max_health
      ? 0
      : Math.min(
          Math.max((conspirator.health ?? 0) / conspirator.max_health, 0),
          1,
        );

  return (
    <Section
      title={
        <>
          {conspirator.name}
          {!!conspirator.is_you && (
            <Box as="span" ml={1} color="label">
              (you)
            </Box>
          )}
        </>
      }
      buttons={
        <Box color={status.color} bold>
          <Icon name={status.icon} mr={1} />
          {status.label}
        </Box>
      }
    >
      <LabeledList>
        <LabeledList.Item label="Rank">
          {conspirator.rank || 'Unknown'}
        </LabeledList.Item>
        <LabeledList.Item label="Job">
          {conspirator.job || 'Unknown'}
        </LabeledList.Item>
        {hasBody && (
          <>
            <LabeledList.Item label="Health">
              <ProgressBar
                value={healthFraction}
                ranges={{
                  good: [0.7, Infinity],
                  average: [0.3, 0.7],
                  bad: [-Infinity, 0.3],
                }}
              >
                {Math.round(healthFraction * 100)}%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Damage">
              <DamageReadout
                label="Brute"
                color="red"
                amount={conspirator.brute}
              />
              <DamageReadout
                label="Burn"
                color="orange"
                amount={conspirator.burn}
              />
              <DamageReadout
                label="Toxin"
                color="green"
                amount={conspirator.toxin}
              />
              <DamageReadout
                label="Oxygen"
                color="blue"
                amount={conspirator.oxygen}
              />
            </LabeledList.Item>
          </>
        )}
      </LabeledList>
    </Section>
  );
};

const DamageReadout = (props: {
  label: string;
  color: string;
  amount?: number;
}) => {
  const { label, color, amount = 0 } = props;
  return (
    <Box inline mr={2} color={amount > 0 ? color : 'label'}>
      {label}: {Math.round(amount)}
    </Box>
  );
};

type GuideTopic = {
  title: string;
  icon: string;
  content: ReactNode;
};

const GUIDE_TOPICS: GuideTopic[] = [
  {
    title: 'The Bond',
    icon: 'link',
    content: (
      <>
        <Box mb={1}>
          Blood brothers are a small team of conspirators working together
          against the station. Every brother in your team shares the same
          objectives, so your team succeeds or fails together.
        </Box>
        <Box mb={1}>
          Use the <b>Blood Bond</b> action to talk privately with your brothers.
          Nobody else on the station can hear it, but ghosts can.
        </Box>
        <Box>
          Your brothers are marked by the blood brother icon on your HUD, and
          their health is shown in the <b>Conspirators</b> tab.
        </Box>
      </>
    ),
  },
  {
    title: 'Getting Started',
    icon: 'flag',
    content: (
      <>
        <Box bold fontSize="14px" color="red" mb={0.5}>
          If you started the round as a blood brother...
        </Box>
        <Box mb={1}>
          You're on your own for now. You start with a <b>flash</b>, and your
          first job is to recruit a brother with it. See the <b>Recruiting</b>{' '}
          topic.
        </Box>
        <Box mb={1}>
          Choose carefully. Once you recruit someone, you can't recruit anyone
          else, so pick someone you can trust and who can help with your
          objectives.
        </Box>
        <Box mb={2}>
          Until then, scout your targets and gather crafting materials. Your
          recruit will need you to fill them in.
        </Box>
        <Box bold fontSize="14px" color="red" mb={0.5}>
          If you were flashed and are reading this...
        </Box>
        <Box mb={1}>
          Welcome to the bond. The person who flashed you is now your brother,
          and you share their objectives. Their goals are your goals now.
        </Box>
        <Box mb={1}>
          Say hello with the <b>Blood Bond</b> action. Your brother has probably
          been planning for a while, so ask them what they need from you.
        </Box>
        <Box>
          You usually won't get a flash of your own, but now and then the
          Syndicate expects more from a recruit and grants an extra one. If that
          happens, you can recruit another brother too.
        </Box>
      </>
    ),
  },
  {
    title: 'Recruiting',
    icon: 'user-plus',
    content: (
      <>
        <Box mb={1}>
          Your first objective is to recruit a brother. Use a flash directly on
          a conscious person. Your starting flash works, and so does any other
          handheld flash. You can even flash them from behind.
        </Box>
        <Box mb={1}>
          They fall asleep and are offered a place in your bond. The flash burns
          out in the process. If they refuse, you can't try to recruit them
          again.
        </Box>
        <Box mb={1}>
          You can't recruit people who are mindshielded, people who already
          belong to another blood brother bond or serve another master, the
          targets of your objectives, or anyone without a mind. Examine a flash
          for more details.
        </Box>
        <Box mb={1}>
          Your flash <b>can</b> recruit other antagonists. Only <i>your</i>{' '}
          targets are off limits, so a traitor sent to kill you can still be
          flashed. Turn your hunter into your brother!
        </Box>
        <Box>
          Recruiting an antagonist, or a member of security or command, brings
          more power to your team, but also more risk. Security and command have
          to be kidnapped and have their mindshield surgically removed first,
          which leaves you exposed while you work. Both draw more attention,
          thanks to their gear, powers or authority. They're also more likely to
          get caught in the crossfire later in the shift, when midround
          antagonists start to appear.
        </Box>
      </>
    ),
  },
  {
    title: 'Team Gear',
    icon: 'parachute-box',
    content: (
      <>
        <Box mb={1}>
          Your team can choose one piece of gear for the whole round. Use the{' '}
          <b>Choose Gear</b> action to propose an option. Every living brother
          has to agree, otherwise the choice is cancelled.
        </Box>
        <Box>
          Once your team agrees, the action becomes <b>Summon Gear</b>, which
          drop-pods the gear to wherever you're standing. Pick a quiet spot!
        </Box>
      </>
    ),
  },
  {
    title: 'Crafting',
    icon: 'hammer',
    content: (
      <>
        <Box mb={1}>
          Blood brothers can build exclusive gear in the <b>Crafting</b> tab.
        </Box>
        <Box mb={1}>
          Recipes use materials in your hands or on the floor around you, and
          some need tools. Turn on <b>Can make only</b> to see what you can
          build right now.
        </Box>
        <Box mb={1}>
          Crafted <b>parts</b> upgrade your modular weapons. See the{' '}
          <b>Modular Weapons</b> topic.
        </Box>
        <Box>
          Can't find a component you need? Ask your fellow conspirators over the
          Blood Bond, or send a <b>mentorhelp</b>. Mentors are happy to tell you
          where things can be found.
        </Box>
      </>
    ),
  },
  {
    title: 'Modular Weapons',
    icon: 'gun',
    content: (
      <>
        <Box mb={1}>
          Blood brother weapons, like the <b>scrap revolver</b> and the{' '}
          <b>hardlight laser cannon</b>, have upgrade slots. Examine a weapon to
          see its slots and what's installed in them.
        </Box>
        <Box mb={1}>
          To install a part, use it on the weapon. To remove one,{' '}
          <b>alt-right-click</b> the weapon while holding it.
        </Box>
        <Box mb={1}>
          A weapon can't fire without a <b>receiver</b>. Receivers set how it
          fires: semi-auto, fully automatic, rifle or carbine.
        </Box>
        <Box mb={1}>
          <b>Ballistic</b> weapons must be fully unloaded before you change
          their parts. <b>Energy</b> weapons can be modified at any time, but
          adding or removing a power cell drains them to zero charge.
        </Box>
        <Box mb={1}>
          The scrap revolver's cylinder can be switched between .38 and 12 gauge
          with a <b>wrench</b>. Unload it first, or a live round will go off in
          your face.
        </Box>
        <Box>
          Not every blood brother weapon is modular. The ones that can't be
          upgraded, like the <b>electrified bola</b>, aren't any worse for it.
          They're built to do their job well right out of the crafting menu.
        </Box>
      </>
    ),
  },
  {
    title: 'Tips',
    icon: 'lightbulb',
    content: (
      <>
        <Box mb={1}>
          Keep in touch. A brother who goes quiet might be in trouble, so check
          the Conspirators tab.
        </Box>
        <Box mb={1}>
          Split up the work. One brother can gather materials while another
          crafts or scouts a target.
        </Box>
        <Box mb={1}>
          Don't flash people near security, or near the crew at all. A flash is
          loud and easy to recognize, which makes it a very good way to get
          caught.
        </Box>
        <Box mb={1}>
          A mindshield stops you from recruiting someone, but it can't break a
          bond that already exists. If you can kidnap a member of security or
          command and get their mindshield out, flash them. They stay your
          brother even if they're implanted again later.
        </Box>
        <Box>
          Your bond is permanent. Cultists and darkspawn thralls can be
          deconverted, but nothing the crew does can turn a blood brother back.
          Other conversion antagonists may recruit more people, but every
          brother you gain is yours for good.
        </Box>
      </>
    ),
  },
];

const GuideTab = (props) => {
  const [topicIndex, setTopicIndex] = useLocalState('bbGuideTopic', 0);
  const topic = GUIDE_TOPICS[topicIndex] ?? GUIDE_TOPICS[0];

  return (
    <Stack fill>
      <Stack.Item width="200px">
        <Section fill>
          <Tabs vertical>
            {GUIDE_TOPICS.map((guideTopic, index) => (
              <Tabs.Tab
                key={guideTopic.title}
                icon={guideTopic.icon}
                selected={index === topicIndex}
                onClick={() => setTopicIndex(index)}
              >
                {guideTopic.title}
              </Tabs.Tab>
            ))}
          </Tabs>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section fill scrollable title={topic.title}>
          <Box fontSize="13px" lineHeight={1.5}>
            {topic.content}
          </Box>
        </Section>
      </Stack.Item>
    </Stack>
  );
};
