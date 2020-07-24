--
-- PostgreSQL database dump
--

-- Dumped from database version 11.4
-- Dumped by pg_dump version 11.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ltree; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;


--
-- Name: EXTENSION ltree; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: enum_ev_stakes_type; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.enum_ev_stakes_type AS ENUM (
    'REWARD',
    'DEPOSIT',
    'WITHDR_REQ',
    'WITHDRAWN',
    'EXIT'
);


ALTER TYPE public.enum_ev_stakes_type OWNER TO sapien;

--
-- Name: enum_mfas_type; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.enum_mfas_type AS ENUM (
    'sms',
    'totp'
);


ALTER TYPE public.enum_mfas_type OWNER TO sapien;

--
-- Name: enum_polls_type; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.enum_polls_type AS ENUM (
    'quiz',
    'poll'
);


ALTER TYPE public.enum_polls_type OWNER TO sapien;

--
-- Name: enum_posts_type; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.enum_posts_type AS ENUM (
    'article',
    'link',
    'poll',
    'media'
);


ALTER TYPE public.enum_posts_type OWNER TO sapien;

--
-- Name: enum_reports_status; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.enum_reports_status AS ENUM (
    'active',
    'dismissed',
    'deleted',
    'suspended'
);


ALTER TYPE public.enum_reports_status OWNER TO sapien;

--
-- Name: enum_reports_type; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.enum_reports_type AS ENUM (
    'spam',
    'abuse',
    'content policy',
    'other'
);


ALTER TYPE public.enum_reports_type OWNER TO sapien;

--
-- Name: enum_votes_type; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.enum_votes_type AS ENUM (
    'up',
    'down'
);


ALTER TYPE public.enum_votes_type OWNER TO sapien;

--
-- Name: group_status; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.group_status AS ENUM (
    'OPEN',
    'CLOSED',
    'DELETED'
);


ALTER TYPE public.group_status OWNER TO sapien;

--
-- Name: group_user_role; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.group_user_role AS ENUM (
    'OWNER',
    'ADMIN',
    'MEMBER'
);


ALTER TYPE public.group_user_role OWNER TO sapien;

--
-- Name: group_user_status; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.group_user_status AS ENUM (
    'SUBSCRIBED',
    'UNSUBSCRIBED',
    'MUTED',
    'ARCHIVED'
);


ALTER TYPE public.group_user_status OWNER TO sapien;

--
-- Name: log_event; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.log_event AS ENUM (
    'MSG_CREATED',
    'MSG_EDITED',
    'MSG_DELETED',
    'MARKED_AS_READ',
    'MARKED_AS_UNREAD',
    'SUBSCRIBED',
    'UNSUBSCRIBED'
);


ALTER TYPE public.log_event OWNER TO sapien;

--
-- Name: media_status; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.media_status AS ENUM (
    'ACTIVE',
    'DELETED'
);


ALTER TYPE public.media_status OWNER TO sapien;

--
-- Name: media_type; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.media_type AS ENUM (
    'VIDEO',
    'AUDIO',
    'IMAGE',
    'DRAWING',
    'PDF',
    'DOCUMENT',
    'PRESENTATION',
    'RECORDING'
);


ALTER TYPE public.media_type OWNER TO sapien;

--
-- Name: message_read_status; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.message_read_status AS ENUM (
    'READ',
    'UNREAD'
);


ALTER TYPE public.message_read_status OWNER TO sapien;

--
-- Name: message_status; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.message_status AS ENUM (
    'VALID',
    'EXPIRED',
    'DELETED'
);


ALTER TYPE public.message_status OWNER TO sapien;

--
-- Name: message_type; Type: TYPE; Schema: public; Owner: sapien
--

CREATE TYPE public.message_type AS ENUM (
    'TEXT',
    'AUDIO',
    'VIDEO',
    'IMAGE',
    'DRAWING'
);


ALTER TYPE public.message_type OWNER TO sapien;

--
-- Name: gen_comment_path(); Type: FUNCTION; Schema: public; Owner: sapien
--

CREATE FUNCTION public.gen_comment_path() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        DECLARE
          parent_path text;
        BEGIN
          IF NEW."isReply" THEN
            SELECT comments.path into parent_path from comments where _id = NEW."parentId";
            NEW.path = parent_path || NEW._id::LTREE;
          END IF;

          IF NOT NEW."isReply" THEN
            NEW.path = NEW."parentId"::LTREE || NEW._id::LTREE;
          END IF;

          RETURN NEW;
        END;
      $$;


ALTER FUNCTION public.gen_comment_path() OWNER TO sapien;

--
-- Name: hot_sort(integer, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: sapien
--

CREATE FUNCTION public.hot_sort(integer, timestamp with time zone) RETURNS double precision
    LANGUAGE sql IMMUTABLE
    AS $_$
    SELECT (CASE WHEN $1 > 0 THEN $1 
        WHEN $1 <= 0 THEN 0
          END)
    /POWER(EXTRACT(EPOCH FROM ((CURRENT_TIMESTAMP - $2) + INTERVAL '2 hours')), 0.85)
        $_$;


ALTER FUNCTION public.hot_sort(integer, timestamp with time zone) OWNER TO sapien;

--
-- Name: inc_comment_counts(); Type: FUNCTION; Schema: public; Owner: sapien
--

CREATE FUNCTION public.inc_comment_counts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        UPDATE posts
          SET comments_count = comments_count + 1
          WHERE _id = NEW."postId";

        IF NEW."isReply" THEN
          UPDATE comments
            SET replies_count = replies_count + 1
            WHERE _id = NEW."parentId";
        END IF;

        RETURN NEW;
      END;
      $$;


ALTER FUNCTION public.inc_comment_counts() OWNER TO sapien;

--
-- Name: unique_short_id(); Type: FUNCTION; Schema: public; Owner: sapien
--

CREATE FUNCTION public.unique_short_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$

      DECLARE
        key   TEXT;
        qry   TEXT;
        found TEXT;
      BEGIN
        -- generate the first part of a query as a string with safely
        -- escaped table name, using || to concat the parts
        qry := 'SELECT "referralCode" FROM ' || quote_ident(TG_TABLE_NAME) || ' WHERE "referralCode"=';

        -- This loop will probably only run once per call until we've generated
        -- millions of ids.
        LOOP

          -- Generate our string bytes and re-encode as a base64 string.
          key := encode(gen_random_bytes(6), 'base64');

          -- Base64 encoding contains 2 URL unsafe characters by default.
          -- The URL-safe version has these replacements.
          key := replace(key, '/', '_'); -- url safe replacement
          key := replace(key, '+', '$'); -- url safe replacement

          -- Concat the generated key (safely quoted) with the generated query
          -- and run it.
          -- SELECT "referralCode" FROM "test" WHERE id='blahblah' INTO found
          -- Now "found" will be the duplicated id or NULL.
          EXECUTE qry || quote_literal(key) INTO found;

          -- Check to see if found is NULL.
          -- If we checked to see if found = NULL it would always be FALSE
          -- because (NULL = NULL) is always FALSE.
          IF found IS NULL THEN
            -- If we didn't find a collision then leave the LOOP.
            EXIT;
          END IF;

          -- We haven't EXITed yet, so return to the top of the LOOP
          -- and try again.
        END LOOP;

        -- NEW and OLD are available in TRIGGER PROCEDURES.
        -- NEW is the mutated row that will actually be INSERTed.
        -- We're replacing id, regardless of what it was before
        -- with our key variable.
        NEW."referralCode" = key;

        -- The RECORD returned here is what will actually be INSERTed,
        -- or what the next trigger will get if there is one.
        RETURN NEW;
      END;
      $_$;


ALTER FUNCTION public.unique_short_id() OWNER TO sapien;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: SequelizeMeta; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public."SequelizeMeta" (
    name character varying(255) NOT NULL
);


ALTER TABLE public."SequelizeMeta" OWNER TO sapien;

--
-- Name: badges; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.badges (
    code character varying(120) NOT NULL
);


ALTER TABLE public.badges OWNER TO sapien;

--
-- Name: blocked_profiles; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.blocked_profiles (
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    blocked_profile_id character varying(100) NOT NULL,
    blocked_by_id character varying(100) NOT NULL
);


ALTER TABLE public.blocked_profiles OWNER TO sapien;

--
-- Name: chat_migrations; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.chat_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


ALTER TABLE public.chat_migrations OWNER TO sapien;

--
-- Name: chat_reports; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.chat_reports (
    id bigint NOT NULL,
    type public.enum_reports_type DEFAULT 'spam'::public.enum_reports_type NOT NULL,
    reason text NOT NULL,
    status public.enum_reports_status DEFAULT 'active'::public.enum_reports_status NOT NULL,
    author_id character varying(255) NOT NULL,
    reporter_id character varying(255) NOT NULL,
    message_id bigint NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.chat_reports OWNER TO sapien;

--
-- Name: chat_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: sapien
--

CREATE SEQUENCE public.chat_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_reports_id_seq OWNER TO sapien;

--
-- Name: chat_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sapien
--

ALTER SEQUENCE public.chat_reports_id_seq OWNED BY public.chat_reports.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.comments (
    _id character varying(100) NOT NULL,
    body character varying(10000000),
    score integer DEFAULT 0 NOT NULL,
    "postId" character varying(120),
    "isReply" boolean DEFAULT false,
    "parentId" character varying(120),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    "profileId" character varying(100),
    rewarded boolean DEFAULT false,
    rewardable boolean DEFAULT true,
    reward_score integer DEFAULT 0,
    negative_charges integer DEFAULT 0,
    "rewardUSPN" bigint,
    "txHash" character varying(66),
    rewarded_at timestamp with time zone,
    "estimatedUSPN" bigint DEFAULT 0,
    hashtags text[] DEFAULT ARRAY[]::text[],
    removed boolean DEFAULT false,
    deleted boolean DEFAULT false,
    replies_count integer DEFAULT 0,
    "shortId" character varying(8),
    path public.ltree
);


ALTER TABLE public.comments OWNER TO sapien;

--
-- Name: echoed_posts; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.echoed_posts (
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    post_id character varying(100) NOT NULL,
    echoed_by_id character varying(100) NOT NULL,
    "deletedAt" timestamp with time zone,
    comment character varying(1000)
);


ALTER TABLE public.echoed_posts OWNER TO sapien;

--
-- Name: ev_content_stakes; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.ev_content_stakes (
    _id character varying(100) NOT NULL,
    tx_hash character varying(66),
    action integer NOT NULL,
    distribution integer,
    "amountUSPN" bigint DEFAULT 0,
    post_id character varying(100),
    comment_id character varying(100),
    sender character(42),
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone
);


ALTER TABLE public.ev_content_stakes OWNER TO sapien;

--
-- Name: ev_stakes; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.ev_stakes (
    _id character varying(100) NOT NULL,
    tx_hash character varying(66),
    type public.enum_ev_stakes_type NOT NULL,
    "depositUSPN" bigint,
    "withdrawalRequestedAt" timestamp with time zone,
    "requestUSPN" bigint,
    "withdrawAt" timestamp with time zone,
    "withdrawUSPN" bigint,
    "exitAt" timestamp with time zone,
    holder character(42),
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone
);


ALTER TABLE public.ev_stakes OWNER TO sapien;

--
-- Name: events; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.events (
    _id character(100) NOT NULL,
    type character varying(20),
    "extraTokensUSPN" bigint,
    "requestedTokensUSPN" bigint,
    "withdrawAfter" integer,
    "releasedTokensUSPN" bigint,
    "slashedTokensUSPN" bigint,
    "slashedReason" character varying(200),
    "firedAt" bigint,
    "txHash" character(66),
    "blockNumber" integer,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    holder character(42)
);


ALTER TABLE public.events OWNER TO sapien;

--
-- Name: feeds; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.feeds (
    _id character varying(100) NOT NULL,
    name character varying(120),
    "tribeIds" jsonb,
    "profileIds" jsonb,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    "profileId" character varying(100)
);


ALTER TABLE public.feeds OWNER TO sapien;

--
-- Name: files; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.files (
    key character varying(1000) NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "deletedAt" timestamp with time zone
);


ALTER TABLE public.files OWNER TO sapien;

--
-- Name: followers; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.followers (
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    following_id character varying(100) NOT NULL,
    follower_id character varying(100) NOT NULL,
    "deletedAt" timestamp with time zone
);


ALTER TABLE public.followers OWNER TO sapien;

--
-- Name: group_users; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.group_users (
    id bigint NOT NULL,
    role public.group_user_role DEFAULT 'MEMBER'::public.group_user_role NOT NULL,
    status public.group_user_status DEFAULT 'SUBSCRIBED'::public.group_user_status NOT NULL,
    bookmarked boolean DEFAULT false NOT NULL,
    group_id bigint NOT NULL,
    profile_id character varying(255) NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.group_users OWNER TO sapien;

--
-- Name: group_users_id_seq; Type: SEQUENCE; Schema: public; Owner: sapien
--

CREATE SEQUENCE public.group_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.group_users_id_seq OWNER TO sapien;

--
-- Name: group_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sapien
--

ALTER SEQUENCE public.group_users_id_seq OWNED BY public.group_users.id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.groups (
    id bigint NOT NULL,
    name character varying(255),
    description text,
    picture text,
    status public.group_status DEFAULT 'OPEN'::public.group_status NOT NULL,
    is_private boolean DEFAULT true NOT NULL,
    last_message_id uuid,
    profile_id character varying(255) NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.groups OWNER TO sapien;

--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: sapien
--

CREATE SEQUENCE public.groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.groups_id_seq OWNER TO sapien;

--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sapien
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: hashtags; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.hashtags (
    _id integer NOT NULL,
    name character varying(40),
    post_score integer,
    comment_score integer,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone
);


ALTER TABLE public.hashtags OWNER TO sapien;

--
-- Name: hashtags__id_seq; Type: SEQUENCE; Schema: public; Owner: sapien
--

CREATE SEQUENCE public.hashtags__id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hashtags__id_seq OWNER TO sapien;

--
-- Name: hashtags__id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sapien
--

ALTER SEQUENCE public.hashtags__id_seq OWNED BY public.hashtags._id;


--
-- Name: media_object; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.media_object (
    id bigint NOT NULL,
    mo_type public.media_type NOT NULL,
    mo_size integer NOT NULL,
    mo_status public.media_status DEFAULT 'ACTIVE'::public.media_status,
    mo_extension text,
    mo_reference_id text,
    mo_for_object_type text,
    mo_for_object_id text,
    mo_sequence integer,
    mo_description text,
    mo_start_date timestamp without time zone,
    mo_end_date timestamp without time zone,
    mo_position numeric DEFAULT 0.0,
    mo_created_by character varying(255) NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.media_object OWNER TO sapien;

--
-- Name: media_object_id_seq; Type: SEQUENCE; Schema: public; Owner: sapien
--

CREATE SEQUENCE public.media_object_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.media_object_id_seq OWNER TO sapien;

--
-- Name: media_object_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sapien
--

ALTER SEQUENCE public.media_object_id_seq OWNED BY public.media_object.id;


--
-- Name: message_groups; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.message_groups (
    id bigint NOT NULL,
    read_status public.message_read_status DEFAULT 'UNREAD'::public.message_read_status NOT NULL,
    message_id bigint NOT NULL,
    group_id bigint NOT NULL,
    profile_id character varying(255) NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.message_groups OWNER TO sapien;

--
-- Name: message_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: sapien
--

CREATE SEQUENCE public.message_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.message_groups_id_seq OWNER TO sapien;

--
-- Name: message_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sapien
--

ALTER SEQUENCE public.message_groups_id_seq OWNED BY public.message_groups.id;


--
-- Name: message_logs; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.message_logs (
    id bigint NOT NULL,
    event public.log_event NOT NULL,
    happen_at timestamp without time zone DEFAULT now() NOT NULL,
    message_id bigint NOT NULL,
    profile_id character varying(255) NOT NULL
);


ALTER TABLE public.message_logs OWNER TO sapien;

--
-- Name: message_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: sapien
--

CREATE SEQUENCE public.message_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.message_logs_id_seq OWNER TO sapien;

--
-- Name: message_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sapien
--

ALTER SEQUENCE public.message_logs_id_seq OWNED BY public.message_logs.id;


--
-- Name: message_reactions; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.message_reactions (
    id bigint NOT NULL,
    value text NOT NULL,
    message_id bigint NOT NULL,
    profile_id character varying(255) NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.message_reactions OWNER TO sapien;

--
-- Name: message_reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: sapien
--

CREATE SEQUENCE public.message_reactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.message_reactions_id_seq OWNER TO sapien;

--
-- Name: message_reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sapien
--

ALTER SEQUENCE public.message_reactions_id_seq OWNED BY public.message_reactions.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    content text,
    type public.message_type DEFAULT 'TEXT'::public.message_type NOT NULL,
    status public.message_status DEFAULT 'VALID'::public.message_status NOT NULL,
    is_request boolean DEFAULT false NOT NULL,
    profile_id character varying(255) NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.messages OWNER TO sapien;

--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: sapien
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.messages_id_seq OWNER TO sapien;

--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sapien
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: mfas; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.mfas (
    _id character varying(100) NOT NULL,
    enabled boolean,
    type public.enum_mfas_type,
    otp_secret text,
    failed_count integer DEFAULT 0,
    backup_codes text[],
    user_id character varying(100),
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone
);


ALTER TABLE public.mfas OWNER TO sapien;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.notifications (
    id uuid NOT NULL,
    sender_id character varying(255),
    sender_name character varying(255),
    sender_thumb character varying(255),
    sender_profile_id character varying(255),
    source character varying(255) DEFAULT 'Sapien'::character varying,
    payload jsonb,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.notifications OWNER TO sapien;

--
-- Name: notifier_migrations; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.notifier_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


ALTER TABLE public.notifier_migrations OWNER TO sapien;

--
-- Name: polls; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.polls (
    _id character varying(100) NOT NULL,
    profile_id character varying(100),
    post_id character varying(100) NOT NULL,
    title character varying(1000) NOT NULL,
    description character varying(10000000),
    tags text[],
    start_at timestamp with time zone NOT NULL,
    end_at timestamp with time zone NOT NULL,
    reward bigint DEFAULT 0,
    sapien_fee bigint,
    type public.enum_polls_type DEFAULT 'poll'::public.enum_polls_type NOT NULL,
    fixed_distribution boolean DEFAULT true,
    consensus_rule double precision,
    min_consensus integer,
    fast_consensus boolean,
    min_people integer,
    max_people integer,
    options jsonb NOT NULL,
    correct_option smallint,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.polls OWNER TO sapien;

--
-- Name: polls_rewards; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.polls_rewards (
    _id integer NOT NULL,
    status character varying(10),
    "txHash" character(66),
    "timestamp" character varying(40),
    transfers jsonb,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    "deletedAt" timestamp with time zone
);


ALTER TABLE public.polls_rewards OWNER TO sapien;

--
-- Name: polls_rewards__id_seq; Type: SEQUENCE; Schema: public; Owner: sapien
--

CREATE SEQUENCE public.polls_rewards__id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.polls_rewards__id_seq OWNER TO sapien;

--
-- Name: polls_rewards__id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sapien
--

ALTER SEQUENCE public.polls_rewards__id_seq OWNED BY public.polls_rewards._id;


--
-- Name: polls_users; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.polls_users (
    poll_id character varying(100) NOT NULL,
    user_id character varying(100) NOT NULL,
    preferred_option smallint NOT NULL,
    join_pool_at timestamp with time zone,
    voted_at timestamp with time zone,
    rewarded boolean,
    "rewardUSPN" bigint,
    rewarded_at timestamp with time zone,
    "txHash" character varying(66),
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.polls_users OWNER TO sapien;

--
-- Name: polls_views; Type: VIEW; Schema: public; Owner: sapien
--

CREATE VIEW public.polls_views AS
 SELECT p._id,
    p.profile_id AS creator,
    p.post_id,
    p.start_at,
    p.end_at,
    p.title,
    p.description,
    p.tags,
    p.reward,
    p.sapien_fee,
    p.type,
    p.options,
    p.correct_option,
    total.total_responses,
    p.fast_consensus,
        CASE
            WHEN (p.start_at > now()) THEN 'WAITING'::text
            WHEN (((p.start_at <= now()) AND (p.fast_consensus = true) AND (consensus.consensus_number_reached = true)) OR ((p.start_at <= now()) AND (p.end_at <= now()))) THEN 'FINISHED'::text
            WHEN (p.start_at <= now()) THEN 'RUNNING'::text
            ELSE NULL::text
        END AS status,
    quiz_winners.number_winners,
        CASE
            WHEN (quiz_winners.number_winners > 0) THEN ((p.reward / quiz_winners.number_winners))::numeric
            ELSE (0)::numeric
        END AS reward_per_winner,
    votes.common_option,
    votes.number_people_consensus,
    (((total.total_responses)::double precision * p.consensus_rule))::integer AS required_consensus_number,
    consensus.consensus_number_reached,
    p.updated_at
   FROM public.polls p,
    LATERAL ( SELECT (d.key)::smallint AS common_option,
            (((d.datas -> 'voted'::text))::text)::integer AS number_people_consensus
           FROM jsonb_each(p.options) d(key, datas)
          ORDER BY (((d.datas -> 'voted'::text))::text)::integer DESC
         LIMIT 1) votes,
    LATERAL ( SELECT sum(((d.datas ->> 'voted'::text))::integer) AS total_responses
           FROM jsonb_each(p.options) d(key, datas)) total,
    LATERAL ( SELECT (((p.options -> (p.correct_option)::text) ->> 'voted'::text))::integer AS number_winners) quiz_winners,
    LATERAL ( SELECT
                CASE
                    WHEN ((p.min_consensus <= votes.number_people_consensus) AND (((total.total_responses)::double precision * p.consensus_rule) <= (votes.number_people_consensus)::double precision)) THEN true
                    WHEN ((p.min_consensus > votes.number_people_consensus) OR (((total.total_responses)::double precision * p.consensus_rule) > (votes.number_people_consensus)::double precision)) THEN false
                    ELSE NULL::boolean
                END AS consensus_number_reached) consensus;


ALTER TABLE public.polls_views OWNER TO sapien;

--
-- Name: posts; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.posts (
    _id character varying(100) NOT NULL,
    tags text[],
    link character varying(5000),
    title character varying(1000),
    score integer DEFAULT 0 NOT NULL,
    content character varying(10000000),
    excerpt character varying(1000),
    rewarded boolean DEFAULT false NOT NULL,
    "imageUrl" character varying(5000),
    "rewardUSPN" bigint,
    rewardable boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    tribe_id character varying(100),
    profile_id character varying(100),
    pinned boolean DEFAULT false,
    reward_score integer DEFAULT 0 NOT NULL,
    "txHash" character varying(66),
    rewarded_at timestamp with time zone,
    negative_charges integer DEFAULT 0,
    "estimatedUSPN" bigint DEFAULT 0,
    type public.enum_posts_type DEFAULT 'article'::public.enum_posts_type NOT NULL,
    thumbnail jsonb DEFAULT '{}'::jsonb,
    hashtags text[] DEFAULT ARRAY[]::text[],
    removed boolean DEFAULT false,
    deleted boolean DEFAULT false,
    comments_count integer DEFAULT 0,
    "isFeatured" boolean DEFAULT false,
    "shortId" character varying(8),
    version integer DEFAULT 1
);


ALTER TABLE public.posts OWNER TO sapien;

--
-- Name: profiles; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.profiles (
    _id character varying(100) NOT NULL,
    points integer DEFAULT 0 NOT NULL,
    badges character varying(120)[],
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    selected_at timestamp with time zone NOT NULL,
    username character varying(255) NOT NULL,
    thumbnail jsonb DEFAULT '{}'::jsonb,
    reputation integer DEFAULT 0 NOT NULL,
    description character varying(1000),
    "displayName" character varying(120) NOT NULL,
    cover_image_url jsonb DEFAULT '{}'::jsonb,
    "privacySettings" jsonb DEFAULT '{"findMe": true, "privatePosts": true, "profilePrivate": true, "privateFollowers": false, "privateFollowing": false, "enabledGoogleAnalytics": true}'::jsonb,
    "contactInformation" jsonb DEFAULT '{"emailAddress": "", "mobileNumber": ""}'::jsonb NOT NULL,
    "emailNotifications" jsonb DEFAULT '{"followers": false, "sapienNews": true}'::jsonb NOT NULL,
    "userId" character varying(100),
    "notificationSettings" jsonb DEFAULT '{"tribes": [], "follower": true, "profiles": []}'::jsonb
);


ALTER TABLE public.profiles OWNER TO sapien;

--
-- Name: receivers; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.receivers (
    id uuid NOT NULL,
    user_id character varying(255),
    read boolean DEFAULT false NOT NULL,
    status character varying(255),
    notification_id uuid,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.receivers OWNER TO sapien;

--
-- Name: referrals; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.referrals (
    "validUntil" timestamp with time zone DEFAULT '2020-07-17 16:02:21.038+03'::timestamp with time zone,
    "totalRewardUSPN" bigint DEFAULT 0 NOT NULL,
    "referreeId" character varying(100),
    "referrerId" character varying(100),
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone
);


ALTER TABLE public.referrals OWNER TO sapien;

--
-- Name: reports; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.reports (
    _id character varying(100) NOT NULL,
    reason character varying(1000),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "deletedAt" timestamp with time zone,
    type public.enum_reports_type DEFAULT 'spam'::public.enum_reports_type,
    status public.enum_reports_status DEFAULT 'active'::public.enum_reports_status,
    "authorId" character varying(100),
    "reporterId" character varying(100),
    "postId" character varying(100),
    "commentId" character varying(100),
    "tribeId" character varying(100)
);


ALTER TABLE public.reports OWNER TO sapien;

--
-- Name: rewards; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.rewards (
    _id integer NOT NULL,
    status character varying(10),
    "txHash" character(66),
    "timestamp" character varying(40),
    transfers jsonb,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    "deletedAt" timestamp with time zone
);


ALTER TABLE public.rewards OWNER TO sapien;

--
-- Name: rewards__id_seq; Type: SEQUENCE; Schema: public; Owner: sapien
--

CREATE SEQUENCE public.rewards__id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rewards__id_seq OWNER TO sapien;

--
-- Name: rewards__id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sapien
--

ALTER SEQUENCE public.rewards__id_seq OWNED BY public.rewards._id;


--
-- Name: saved_comments; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.saved_comments (
    _id character varying(100) NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "commentId" character varying(100),
    "profileId" character varying(100)
);


ALTER TABLE public.saved_comments OWNER TO sapien;

--
-- Name: saved_contents; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.saved_contents (
    _id character varying(100) NOT NULL,
    url character varying(1000) NOT NULL,
    name character varying(1000) NOT NULL,
    type character varying(1000) NOT NULL,
    source character varying(1000) NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "deletedAt" timestamp with time zone
);


ALTER TABLE public.saved_contents OWNER TO sapien;

--
-- Name: saved_posts; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.saved_posts (
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    post_id character varying(100) NOT NULL,
    profile_id character varying(100) NOT NULL,
    "deletedAt" timestamp with time zone
);


ALTER TABLE public.saved_posts OWNER TO sapien;

--
-- Name: services; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.services (
    _id integer,
    key character varying(1000) NOT NULL,
    value json,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone
);


ALTER TABLE public.services OWNER TO sapien;

--
-- Name: stakes; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.stakes (
    address character(42) NOT NULL,
    "isMainAddress" boolean,
    "totalStakedUSPN" bigint DEFAULT 0 NOT NULL,
    "lastTx" character varying(66),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    user_id character varying(100),
    "timestamp" integer DEFAULT 0,
    network_id integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.stakes OWNER TO sapien;

--
-- Name: tribe_leaderboard_members; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.tribe_leaderboard_members (
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    tribe_id character varying(100) NOT NULL,
    profile_id character varying(100) NOT NULL
);


ALTER TABLE public.tribe_leaderboard_members OWNER TO sapien;

--
-- Name: tribe_profiles; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.tribe_profiles (
    tribe_id character varying(100) NOT NULL,
    profile_id character varying(100) NOT NULL,
    role character varying(20),
    following boolean DEFAULT false,
    notifications boolean DEFAULT false,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    "deletedAt" timestamp with time zone,
    notification_id uuid,
    _id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    report_id character varying(100)
);


ALTER TABLE public.tribe_profiles OWNER TO sapien;

--
-- Name: tribes; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.tribes (
    _id character varying(100) NOT NULL,
    name character varying(120) NOT NULL,
    rules jsonb DEFAULT '[{"_id": "0", "name": "Do not post illegal content.", "description": "Do not post illegal content."}, {"_id": "1", "name": "Do not post content that incites violence or threatens individuals.", "description": "Do not post content that incites violence or threatens individuals."}, {"_id": "2", "name": "Do not post personal and confidential information.", "description": "Do not post personal and confidential information."}]'::jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    is_default boolean DEFAULT false,
    description text,
    cover_image_url jsonb DEFAULT '{}'::jsonb,
    profile_image_url jsonb DEFAULT '{}'::jsonb,
    "createdById" character varying(100),
    "profileId" character varying(100),
    post_count integer DEFAULT 0 NOT NULL,
    follower_count integer DEFAULT 0 NOT NULL,
    type character varying(20) DEFAULT 'public'::character varying NOT NULL,
    is_nsfw boolean DEFAULT false,
    roles jsonb DEFAULT '{"ADMIN": {"can": ["removePost", "suspendUser", "removeComment", "updateTribeRules", "updateMemberStatus", "revokeTribeInvite", "removeTribeMember", "sendInviteToJoinTribe", "updateMemberRole", "updateTribeCoverPicture", "updateTribeProfilePicture", "updateTribeOverview", "updateTribeType", "inviteModerators", "revokeModeratorInvite", "updateAllowJoinRequests"], "inherits": ["MODERATOR"]}, "OWNER": {"can": ["deleteTribe", "transferTribeOwnership"], "inherits": ["ADMIN"]}, "MEMBER": {"can": ["viewTribe", "editPost", "insertPost", "editComment", "insertComment"]}, "INVITED": {"can": ["acceptTribeInvite", "declineTribeInvite"]}, "MODERATOR": {"can": ["viewSettings", "viewTribeIssues", "updateReportStatus"], "inherits": ["MEMBER"]}, "REQUESTED": {"can": []}, "SUSPENDED": {"can": []}, "INVITED_TO_MODERATE": {"can": ["acceptModeratorInvite", "declineModeratorInvite"]}}'::jsonb,
    allow_join_requests boolean DEFAULT true
);


ALTER TABLE public.tribes OWNER TO sapien;

--
-- Name: tx_data; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.tx_data (
    tx_hash character varying(66) NOT NULL,
    network_id integer NOT NULL,
    fired_at bigint,
    block_number integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.tx_data OWNER TO sapien;

--
-- Name: users; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.users (
    _id character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    password text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    verify_phone jsonb DEFAULT '{"code": "", "verified": false, "validUntil": "", "phoneNumber": ""}'::jsonb,
    use_post_capacity boolean DEFAULT true,
    use_vote_capacity boolean DEFAULT true,
    email_confirmed boolean DEFAULT false,
    init_stake_sent boolean DEFAULT false,
    total_rewards_received bigint DEFAULT 0,
    must_choose_profile boolean DEFAULT false,
    is_admin boolean DEFAULT false,
    is_bot boolean DEFAULT false,
    "referralCode" character varying(8)
);


ALTER TABLE public.users OWNER TO sapien;

--
-- Name: votes; Type: TABLE; Schema: public; Owner: sapien
--

CREATE TABLE public.votes (
    _id character varying(100) NOT NULL,
    type public.enum_votes_type,
    capacity_used boolean,
    re_captcha_score double precision,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    post_id character varying(100),
    comment_id character varying(100),
    profile_id character varying(100)
);


ALTER TABLE public.votes OWNER TO sapien;

--
-- Name: chat_reports id; Type: DEFAULT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.chat_reports ALTER COLUMN id SET DEFAULT nextval('public.chat_reports_id_seq'::regclass);


--
-- Name: group_users id; Type: DEFAULT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.group_users ALTER COLUMN id SET DEFAULT nextval('public.group_users_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: hashtags _id; Type: DEFAULT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.hashtags ALTER COLUMN _id SET DEFAULT nextval('public.hashtags__id_seq'::regclass);


--
-- Name: media_object id; Type: DEFAULT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.media_object ALTER COLUMN id SET DEFAULT nextval('public.media_object_id_seq'::regclass);


--
-- Name: message_groups id; Type: DEFAULT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.message_groups ALTER COLUMN id SET DEFAULT nextval('public.message_groups_id_seq'::regclass);


--
-- Name: message_logs id; Type: DEFAULT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.message_logs ALTER COLUMN id SET DEFAULT nextval('public.message_logs_id_seq'::regclass);


--
-- Name: message_reactions id; Type: DEFAULT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.message_reactions ALTER COLUMN id SET DEFAULT nextval('public.message_reactions_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: polls_rewards _id; Type: DEFAULT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.polls_rewards ALTER COLUMN _id SET DEFAULT nextval('public.polls_rewards__id_seq'::regclass);


--
-- Name: rewards _id; Type: DEFAULT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.rewards ALTER COLUMN _id SET DEFAULT nextval('public.rewards__id_seq'::regclass);


--
-- Name: SequelizeMeta SequelizeMeta_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public."SequelizeMeta"
    ADD CONSTRAINT "SequelizeMeta_pkey" PRIMARY KEY (name);


--
-- Name: badges badges_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.badges
    ADD CONSTRAINT badges_pkey PRIMARY KEY (code);


--
-- Name: blocked_profiles blocked_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.blocked_profiles
    ADD CONSTRAINT blocked_profiles_pkey PRIMARY KEY (blocked_profile_id, blocked_by_id);


--
-- Name: chat_migrations chat_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.chat_migrations
    ADD CONSTRAINT chat_migrations_pkey PRIMARY KEY (version);


--
-- Name: chat_reports chat_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.chat_reports
    ADD CONSTRAINT chat_reports_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (_id);


--
-- Name: echoed_posts echoed_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.echoed_posts
    ADD CONSTRAINT echoed_posts_pkey PRIMARY KEY (post_id, echoed_by_id);


--
-- Name: ev_content_stakes ev_content_stakes_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.ev_content_stakes
    ADD CONSTRAINT ev_content_stakes_pkey PRIMARY KEY (_id);


--
-- Name: ev_stakes ev_stakes_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.ev_stakes
    ADD CONSTRAINT ev_stakes_pkey PRIMARY KEY (_id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (_id);


--
-- Name: feeds feeds_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.feeds
    ADD CONSTRAINT feeds_pkey PRIMARY KEY (_id);


--
-- Name: files files_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_pkey PRIMARY KEY (key);


--
-- Name: followers followers_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_pkey PRIMARY KEY (following_id, follower_id);


--
-- Name: group_users group_users_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.group_users
    ADD CONSTRAINT group_users_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: hashtags hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.hashtags
    ADD CONSTRAINT hashtags_pkey PRIMARY KEY (_id);


--
-- Name: media_object media_object_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.media_object
    ADD CONSTRAINT media_object_pkey PRIMARY KEY (id);


--
-- Name: message_groups message_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.message_groups
    ADD CONSTRAINT message_groups_pkey PRIMARY KEY (id);


--
-- Name: message_logs message_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.message_logs
    ADD CONSTRAINT message_logs_pkey PRIMARY KEY (id);


--
-- Name: message_reactions message_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.message_reactions
    ADD CONSTRAINT message_reactions_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: mfas mfas_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.mfas
    ADD CONSTRAINT mfas_pkey PRIMARY KEY (_id);


--
-- Name: mfas mfas_user_id_key; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.mfas
    ADD CONSTRAINT mfas_user_id_key UNIQUE (user_id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: notifier_migrations notifier_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.notifier_migrations
    ADD CONSTRAINT notifier_migrations_pkey PRIMARY KEY (version);


--
-- Name: polls polls_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.polls
    ADD CONSTRAINT polls_pkey PRIMARY KEY (_id);


--
-- Name: polls polls_post_id_key; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.polls
    ADD CONSTRAINT polls_post_id_key UNIQUE (post_id);


--
-- Name: polls_rewards polls_rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.polls_rewards
    ADD CONSTRAINT polls_rewards_pkey PRIMARY KEY (_id);


--
-- Name: polls_users polls_users_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.polls_users
    ADD CONSTRAINT polls_users_pkey PRIMARY KEY (poll_id, user_id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (_id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (_id);


--
-- Name: receivers receivers_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.receivers
    ADD CONSTRAINT receivers_pkey PRIMARY KEY (id);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (_id);


--
-- Name: rewards rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.rewards
    ADD CONSTRAINT rewards_pkey PRIMARY KEY (_id);


--
-- Name: saved_comments saved_comments_commentId_profileId_key; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.saved_comments
    ADD CONSTRAINT "saved_comments_commentId_profileId_key" UNIQUE ("commentId", "profileId");


--
-- Name: saved_comments saved_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.saved_comments
    ADD CONSTRAINT saved_comments_pkey PRIMARY KEY (_id);


--
-- Name: saved_contents saved_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.saved_contents
    ADD CONSTRAINT saved_contents_pkey PRIMARY KEY (_id);


--
-- Name: saved_posts saved_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.saved_posts
    ADD CONSTRAINT saved_posts_pkey PRIMARY KEY (post_id, profile_id);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (key);


--
-- Name: stakes stakes_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.stakes
    ADD CONSTRAINT stakes_pkey PRIMARY KEY (address);


--
-- Name: tribe_leaderboard_members tribe_leaderboard_members_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.tribe_leaderboard_members
    ADD CONSTRAINT tribe_leaderboard_members_pkey PRIMARY KEY (tribe_id, profile_id);


--
-- Name: tribe_profiles tribe_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.tribe_profiles
    ADD CONSTRAINT tribe_profiles_pkey PRIMARY KEY (_id);


--
-- Name: tribe_profiles tribe_profiles_unique_tribe_profile; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.tribe_profiles
    ADD CONSTRAINT tribe_profiles_unique_tribe_profile UNIQUE (tribe_id, profile_id);


--
-- Name: tribes tribes_name_key; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.tribes
    ADD CONSTRAINT tribes_name_key UNIQUE (name);


--
-- Name: tribes tribes_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.tribes
    ADD CONSTRAINT tribes_pkey PRIMARY KEY (_id);


--
-- Name: tx_data tx_data_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.tx_data
    ADD CONSTRAINT tx_data_pkey PRIMARY KEY (tx_hash);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (_id);


--
-- Name: votes votes_pkey; Type: CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_pkey PRIMARY KEY (_id);


--
-- Name: events_tx_hash; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX events_tx_hash ON public.events USING btree ("txHash");


--
-- Name: group_users_group_id_profile_id_index; Type: INDEX; Schema: public; Owner: sapien
--

CREATE UNIQUE INDEX group_users_group_id_profile_id_index ON public.group_users USING btree (group_id, profile_id);


--
-- Name: idx_charge_sort_posts; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX idx_charge_sort_posts ON public.posts USING btree (public.hot_sort(reward_score, created_at));


--
-- Name: idx_comments_path; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX idx_comments_path ON public.comments USING gist (path);


--
-- Name: idx_created_at_score_posts; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX idx_created_at_score_posts ON public.posts USING btree (created_at, score);


--
-- Name: idx_follower_count_tribes; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX idx_follower_count_tribes ON public.tribes USING btree (follower_count);


--
-- Name: idx_fts_posts; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX idx_fts_posts ON public.posts USING gin (to_tsvector('english'::regconfig, (title)::text));


--
-- Name: idx_fts_tribes; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX idx_fts_tribes ON public.tribes USING gin (to_tsvector('english'::regconfig, (name)::text));


--
-- Name: idx_hot_sort_posts; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX idx_hot_sort_posts ON public.posts USING btree (public.hot_sort(score, created_at));


--
-- Name: idx_trgm_posts_title; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX idx_trgm_posts_title ON public.posts USING gin (title public.gin_trgm_ops);


--
-- Name: idx_trgm_profiles_display_name; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX idx_trgm_profiles_display_name ON public.profiles USING gin ("displayName" public.gin_trgm_ops);


--
-- Name: idx_trgm_profiles_username; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX idx_trgm_profiles_username ON public.profiles USING gin (username public.gin_trgm_ops);


--
-- Name: idx_trgm_tribes_name; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX idx_trgm_tribes_name ON public.tribes USING gin (name public.gin_trgm_ops);


--
-- Name: idx_tribe_profiles_tribe_id_profile_id; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX idx_tribe_profiles_tribe_id_profile_id ON public.tribe_profiles USING btree (tribe_id, profile_id);


--
-- Name: message_groups_message_id_group_id_profile_id_index; Type: INDEX; Schema: public; Owner: sapien
--

CREATE UNIQUE INDEX message_groups_message_id_group_id_profile_id_index ON public.message_groups USING btree (message_id, group_id, profile_id);


--
-- Name: message_reactions_message_id_profile_id_value_index; Type: INDEX; Schema: public; Owner: sapien
--

CREATE UNIQUE INDEX message_reactions_message_id_profile_id_value_index ON public.message_reactions USING btree (message_id, profile_id, value);


--
-- Name: posts_short_id; Type: INDEX; Schema: public; Owner: sapien
--

CREATE UNIQUE INDEX posts_short_id ON public.posts USING btree ("shortId");


--
-- Name: receivers_notification_id_user_id_index; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX receivers_notification_id_user_id_index ON public.receivers USING btree (notification_id, user_id);


--
-- Name: users_display_name_trgm; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX users_display_name_trgm ON public.profiles USING gin ("displayName" public.gin_trgm_ops);


--
-- Name: users_username_trgm; Type: INDEX; Schema: public; Owner: sapien
--

CREATE INDEX users_username_trgm ON public.profiles USING gin (username public.gin_trgm_ops);


--
-- Name: comments comment_counts; Type: TRIGGER; Schema: public; Owner: sapien
--

CREATE TRIGGER comment_counts AFTER INSERT ON public.comments FOR EACH ROW EXECUTE PROCEDURE public.inc_comment_counts();


--
-- Name: comments comment_path; Type: TRIGGER; Schema: public; Owner: sapien
--

CREATE TRIGGER comment_path BEFORE INSERT ON public.comments FOR EACH ROW EXECUTE PROCEDURE public.gen_comment_path();


--
-- Name: comments comments_short_id; Type: TRIGGER; Schema: public; Owner: sapien
--

CREATE TRIGGER comments_short_id BEFORE INSERT OR UPDATE OF "shortId" ON public.comments FOR EACH ROW EXECUTE PROCEDURE public.unique_short_id();


--
-- Name: posts posts_shortid; Type: TRIGGER; Schema: public; Owner: sapien
--

CREATE TRIGGER posts_shortid BEFORE INSERT OR UPDATE OF "shortId" ON public.posts FOR EACH ROW EXECUTE PROCEDURE public.unique_short_id();


--
-- Name: users users_referral_code; Type: TRIGGER; Schema: public; Owner: sapien
--

CREATE TRIGGER users_referral_code BEFORE INSERT OR UPDATE OF "referralCode" ON public.users FOR EACH ROW EXECUTE PROCEDURE public.unique_short_id();


--
-- Name: blocked_profiles blocked_profiles_blocked_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.blocked_profiles
    ADD CONSTRAINT blocked_profiles_blocked_by_id_fkey FOREIGN KEY (blocked_by_id) REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: blocked_profiles blocked_profiles_blocked_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.blocked_profiles
    ADD CONSTRAINT blocked_profiles_blocked_profile_id_fkey FOREIGN KEY (blocked_profile_id) REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: chat_reports chat_reports_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.chat_reports
    ADD CONSTRAINT chat_reports_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(_id);


--
-- Name: chat_reports chat_reports_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.chat_reports
    ADD CONSTRAINT chat_reports_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: chat_reports chat_reports_reporter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.chat_reports
    ADD CONSTRAINT chat_reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.profiles(_id);


--
-- Name: comments comments_postId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT "comments_postId_fkey" FOREIGN KEY ("postId") REFERENCES public.posts(_id) ON UPDATE CASCADE;


--
-- Name: comments comments_profileId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT "comments_profileId_fkey" FOREIGN KEY ("profileId") REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: echoed_posts echoed_posts_echoed_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.echoed_posts
    ADD CONSTRAINT echoed_posts_echoed_by_id_fkey FOREIGN KEY (echoed_by_id) REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: echoed_posts echoed_posts_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.echoed_posts
    ADD CONSTRAINT echoed_posts_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ev_content_stakes ev_content_stakes_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.ev_content_stakes
    ADD CONSTRAINT ev_content_stakes_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: ev_content_stakes ev_content_stakes_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.ev_content_stakes
    ADD CONSTRAINT ev_content_stakes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: ev_content_stakes ev_content_stakes_sender_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.ev_content_stakes
    ADD CONSTRAINT ev_content_stakes_sender_fkey FOREIGN KEY (sender) REFERENCES public.stakes(address) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: ev_content_stakes ev_content_stakes_tx_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.ev_content_stakes
    ADD CONSTRAINT ev_content_stakes_tx_hash_fkey FOREIGN KEY (tx_hash) REFERENCES public.tx_data(tx_hash) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: ev_stakes ev_stakes_holder_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.ev_stakes
    ADD CONSTRAINT ev_stakes_holder_fkey FOREIGN KEY (holder) REFERENCES public.stakes(address) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: ev_stakes ev_stakes_tx_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.ev_stakes
    ADD CONSTRAINT ev_stakes_tx_hash_fkey FOREIGN KEY (tx_hash) REFERENCES public.tx_data(tx_hash) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: events events_holder_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_holder_fkey FOREIGN KEY (holder) REFERENCES public.stakes(address) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: feeds feeds_profileId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.feeds
    ADD CONSTRAINT "feeds_profileId_fkey" FOREIGN KEY ("profileId") REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: followers followers_follower_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: followers followers_following_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_following_id_fkey FOREIGN KEY (following_id) REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: group_users group_users_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.group_users
    ADD CONSTRAINT group_users_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: group_users group_users_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.group_users
    ADD CONSTRAINT group_users_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(_id);


--
-- Name: groups groups_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(_id);


--
-- Name: media_object media_object_mo_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.media_object
    ADD CONSTRAINT media_object_mo_created_by_fkey FOREIGN KEY (mo_created_by) REFERENCES public.profiles(_id);


--
-- Name: message_groups message_groups_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.message_groups
    ADD CONSTRAINT message_groups_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: message_groups message_groups_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.message_groups
    ADD CONSTRAINT message_groups_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: message_groups message_groups_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.message_groups
    ADD CONSTRAINT message_groups_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(_id);


--
-- Name: message_logs message_logs_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.message_logs
    ADD CONSTRAINT message_logs_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: message_logs message_logs_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.message_logs
    ADD CONSTRAINT message_logs_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(_id);


--
-- Name: message_reactions message_reactions_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.message_reactions
    ADD CONSTRAINT message_reactions_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: message_reactions message_reactions_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.message_reactions
    ADD CONSTRAINT message_reactions_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(_id);


--
-- Name: messages messages_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(_id);


--
-- Name: mfas mfas_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.mfas
    ADD CONSTRAINT mfas_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: polls polls_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.polls
    ADD CONSTRAINT polls_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: polls polls_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.polls
    ADD CONSTRAINT polls_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: polls_users polls_users_poll_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.polls_users
    ADD CONSTRAINT polls_users_poll_id_fkey FOREIGN KEY (poll_id) REFERENCES public.polls(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: polls_users polls_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.polls_users
    ADD CONSTRAINT polls_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: posts posts_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: posts posts_tribe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_tribe_id_fkey FOREIGN KEY (tribe_id) REFERENCES public.tribes(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: profiles profiles_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT "profiles_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: receivers receivers_notification_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.receivers
    ADD CONSTRAINT receivers_notification_id_fkey FOREIGN KEY (notification_id) REFERENCES public.notifications(id) ON DELETE CASCADE;


--
-- Name: referrals referrals_referreeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT "referrals_referreeId_fkey" FOREIGN KEY ("referreeId") REFERENCES public.users(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: referrals referrals_referrerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT "referrals_referrerId_fkey" FOREIGN KEY ("referrerId") REFERENCES public.users(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: reports reports_authorId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT "reports_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: reports reports_commentId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT "reports_commentId_fkey" FOREIGN KEY ("commentId") REFERENCES public.comments(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: reports reports_postId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT "reports_postId_fkey" FOREIGN KEY ("postId") REFERENCES public.posts(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: reports reports_reporterId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT "reports_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: reports reports_tribeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT "reports_tribeId_fkey" FOREIGN KEY ("tribeId") REFERENCES public.tribes(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: saved_comments saved_comments_commentId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.saved_comments
    ADD CONSTRAINT "saved_comments_commentId_fkey" FOREIGN KEY ("commentId") REFERENCES public.comments(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: saved_comments saved_comments_profileId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.saved_comments
    ADD CONSTRAINT "saved_comments_profileId_fkey" FOREIGN KEY ("profileId") REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: saved_posts saved_posts_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.saved_posts
    ADD CONSTRAINT saved_posts_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: saved_posts saved_posts_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.saved_posts
    ADD CONSTRAINT saved_posts_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: stakes stakes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.stakes
    ADD CONSTRAINT stakes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: tribe_leaderboard_members tribe_leaderboard_members_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.tribe_leaderboard_members
    ADD CONSTRAINT tribe_leaderboard_members_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tribe_leaderboard_members tribe_leaderboard_members_tribe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.tribe_leaderboard_members
    ADD CONSTRAINT tribe_leaderboard_members_tribe_id_fkey FOREIGN KEY (tribe_id) REFERENCES public.tribes(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tribe_profiles tribe_profiles_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.tribe_profiles
    ADD CONSTRAINT tribe_profiles_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tribe_profiles tribe_profiles_reports_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.tribe_profiles
    ADD CONSTRAINT tribe_profiles_reports_by_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tribe_profiles tribe_profiles_tribe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.tribe_profiles
    ADD CONSTRAINT tribe_profiles_tribe_id_fkey FOREIGN KEY (tribe_id) REFERENCES public.tribes(_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tribes tribes_createdById_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.tribes
    ADD CONSTRAINT "tribes_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: tribes tribes_profileId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.tribes
    ADD CONSTRAINT "tribes_profileId_fkey" FOREIGN KEY ("profileId") REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: votes votes_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: votes votes_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: votes votes_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sapien
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(_id) ON UPDATE CASCADE ON DELETE SET NULL;

--
-- Data for Name: chat_migrations; Type: TABLE DATA; Schema: public; Owner: sapien
--

COPY public.chat_migrations (version, inserted_at) FROM stdin;
20190718002331	2020-01-13 01:37:55
20190718002847	2020-01-13 01:37:55
20190718003511	2020-01-13 01:37:55
20190724221745	2020-01-13 01:37:55
20190807090748	2020-01-13 01:37:55
20190811203434	2020-01-13 01:37:55
20191114191257	2020-01-13 01:38:52
20191231031016	2020-01-13 01:38:52
20200111112636	2020-01-13 01:38:52
20200113001155	2020-01-13 01:38:52
\.

--
-- PostgreSQL database dump complete
--

