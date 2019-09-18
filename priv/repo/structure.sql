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
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: group_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.group_state AS ENUM (
    'OPEN',
    'CLOSED',
    'DELETED'
);


--
-- Name: group_user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.group_user_role AS ENUM (
    'OWNER',
    'ADMIN',
    'MEMBER'
);


--
-- Name: group_user_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.group_user_state AS ENUM (
    'SUBSCRIBED',
    'UNSUBSCRIBED',
    'MUTED',
    'ARCHIVED'
);


--
-- Name: log_event; Type: TYPE; Schema: public; Owner: -
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


--
-- Name: message_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.message_state AS ENUM (
    'VALID',
    'EXPIRED',
    'DELETED'
);


--
-- Name: message_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.message_type AS ENUM (
    'TEXT',
    'AUDIO',
    'VIDEO',
    'IMAGE',
    'DRAWING'
);


--
-- Name: message_user_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.message_user_state AS ENUM (
    'READ',
    'UNREAD'
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: blocked_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blocked_profiles (
    inserted_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    blocked_profile_id character varying(255) NOT NULL,
    blocked_by_id character varying(255) NOT NULL
);


--
-- Name: files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.files (
    id bigint NOT NULL,
    filename text NOT NULL,
    content_type text,
    size integer NOT NULL,
    user_id character varying(255) NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.files_id_seq OWNED BY public.files.id;


--
-- Name: followers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.followers (
    follower_id character varying(255) NOT NULL,
    following_id character varying(255) NOT NULL,
    inserted_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: group_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_users (
    id bigint NOT NULL,
    role public.group_user_role DEFAULT 'MEMBER'::public.group_user_role NOT NULL,
    state public.group_user_state DEFAULT 'SUBSCRIBED'::public.group_user_state NOT NULL,
    bookmarked boolean DEFAULT false NOT NULL,
    group_id bigint NOT NULL,
    user_id character varying(255) NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: group_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_users_id_seq OWNED BY public.group_users.id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id bigint NOT NULL,
    name character varying(255),
    description text,
    picture text,
    state public.group_state DEFAULT 'OPEN'::public.group_state NOT NULL,
    is_private boolean DEFAULT true NOT NULL,
    last_message_id uuid,
    user_id character varying(255) NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: message_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_files (
    id bigint NOT NULL,
    message_id bigint NOT NULL,
    file_id bigint NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: message_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.message_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.message_files_id_seq OWNED BY public.message_files.id;


--
-- Name: message_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_groups (
    id bigint NOT NULL,
    message_id bigint NOT NULL,
    group_id bigint NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: message_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.message_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.message_groups_id_seq OWNED BY public.message_groups.id;


--
-- Name: message_reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_reactions (
    id bigint NOT NULL,
    value text NOT NULL,
    message_id bigint NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: message_reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.message_reactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.message_reactions_id_seq OWNED BY public.message_reactions.id;


--
-- Name: message_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_users (
    id bigint NOT NULL,
    state public.message_user_state DEFAULT 'UNREAD'::public.message_user_state NOT NULL,
    group_id bigint,
    message_id bigint NOT NULL,
    user_id character varying(255) NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: message_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.message_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.message_users_id_seq OWNED BY public.message_users.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    body text,
    type public.message_type DEFAULT 'TEXT'::public.message_type NOT NULL,
    state public.message_state DEFAULT 'VALID'::public.message_state NOT NULL,
    is_request boolean DEFAULT false NOT NULL,
    user_id character varying(255) NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: user_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_log (
    id bigint NOT NULL,
    event public.log_event NOT NULL,
    happen_at timestamp without time zone DEFAULT now() NOT NULL,
    message_id bigint NOT NULL,
    user_id character varying(255) NOT NULL
);


--
-- Name: user_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_log_id_seq OWNED BY public.user_log.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id character varying(255) NOT NULL,
    username public.citext NOT NULL,
    display_name text NOT NULL,
    email public.citext NOT NULL,
    profile_id character varying(255) NOT NULL,
    avatar text,
    inserted_at timestamp without time zone,
    updated_at timestamp without time zone,
    time_zone text
);


--
-- Name: files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.files ALTER COLUMN id SET DEFAULT nextval('public.files_id_seq'::regclass);


--
-- Name: group_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_users ALTER COLUMN id SET DEFAULT nextval('public.group_users_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: message_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_files ALTER COLUMN id SET DEFAULT nextval('public.message_files_id_seq'::regclass);


--
-- Name: message_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_groups ALTER COLUMN id SET DEFAULT nextval('public.message_groups_id_seq'::regclass);


--
-- Name: message_reactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_reactions ALTER COLUMN id SET DEFAULT nextval('public.message_reactions_id_seq'::regclass);


--
-- Name: message_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_users ALTER COLUMN id SET DEFAULT nextval('public.message_users_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: user_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_log ALTER COLUMN id SET DEFAULT nextval('public.user_log_id_seq'::regclass);


--
-- Name: blocked_profiles blocked_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocked_profiles
    ADD CONSTRAINT blocked_profiles_pkey PRIMARY KEY (blocked_profile_id, blocked_by_id);


--
-- Name: files files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);


--
-- Name: followers followers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_pkey PRIMARY KEY (follower_id, following_id);


--
-- Name: group_users group_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_users
    ADD CONSTRAINT group_users_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: message_files message_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_files
    ADD CONSTRAINT message_files_pkey PRIMARY KEY (id);


--
-- Name: message_groups message_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_groups
    ADD CONSTRAINT message_groups_pkey PRIMARY KEY (id);


--
-- Name: message_reactions message_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_reactions
    ADD CONSTRAINT message_reactions_pkey PRIMARY KEY (id);


--
-- Name: message_users message_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_users
    ADD CONSTRAINT message_users_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: user_log user_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_log
    ADD CONSTRAINT user_log_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: blocked_profiles_blocked_profile_id_blocked_by_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX blocked_profiles_blocked_profile_id_blocked_by_id_index ON public.blocked_profiles USING btree (blocked_profile_id, blocked_by_id);


--
-- Name: followers_following_id_follower_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX followers_following_id_follower_id_index ON public.followers USING btree (following_id, follower_id);


--
-- Name: group_users_group_id_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX group_users_group_id_user_id_index ON public.group_users USING btree (group_id, user_id);


--
-- Name: message_files_file_id_message_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX message_files_file_id_message_id_index ON public.message_files USING btree (file_id, message_id);


--
-- Name: message_files_message_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX message_files_message_id_index ON public.message_files USING btree (message_id);


--
-- Name: message_groups_message_id_group_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX message_groups_message_id_group_id_index ON public.message_groups USING btree (message_id, group_id);


--
-- Name: message_reactions_message_id_value_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX message_reactions_message_id_value_index ON public.message_reactions USING btree (message_id, value);


--
-- Name: message_users_message_id_group_id_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX message_users_message_id_group_id_user_id_index ON public.message_users USING btree (message_id, group_id, user_id);


--
-- Name: message_users_message_id_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX message_users_message_id_user_id_index ON public.message_users USING btree (message_id, user_id);


--
-- Name: users_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_id_index ON public.users USING btree (id);


--
-- Name: users_lower_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_lower_email_index ON public.users USING btree (lower((email)::text));


--
-- Name: users_lower_username_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_lower_username_index ON public.users USING btree (lower((username)::text));


--
-- Name: users_profile_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_profile_id_index ON public.users USING btree (profile_id);


--
-- Name: blocked_profiles blocked_profiles_blocked_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocked_profiles
    ADD CONSTRAINT blocked_profiles_blocked_by_id_fkey FOREIGN KEY (blocked_by_id) REFERENCES public.users(profile_id) ON DELETE CASCADE;


--
-- Name: blocked_profiles blocked_profiles_blocked_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocked_profiles
    ADD CONSTRAINT blocked_profiles_blocked_profile_id_fkey FOREIGN KEY (blocked_profile_id) REFERENCES public.users(profile_id) ON DELETE CASCADE;


--
-- Name: files files_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: followers followers_follower_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES public.users(profile_id) ON DELETE CASCADE;


--
-- Name: followers followers_following_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_following_id_fkey FOREIGN KEY (following_id) REFERENCES public.users(profile_id) ON DELETE CASCADE;


--
-- Name: group_users group_users_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_users
    ADD CONSTRAINT group_users_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: group_users group_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_users
    ADD CONSTRAINT group_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: groups groups_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: message_files message_files_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_files
    ADD CONSTRAINT message_files_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.files(id);


--
-- Name: message_files message_files_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_files
    ADD CONSTRAINT message_files_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: message_groups message_groups_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_groups
    ADD CONSTRAINT message_groups_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: message_groups message_groups_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_groups
    ADD CONSTRAINT message_groups_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: message_reactions message_reactions_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_reactions
    ADD CONSTRAINT message_reactions_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: message_users message_users_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_users
    ADD CONSTRAINT message_users_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: message_users message_users_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_users
    ADD CONSTRAINT message_users_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: message_users message_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_users
    ADD CONSTRAINT message_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: messages messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_log user_log_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_log
    ADD CONSTRAINT user_log_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: user_log user_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_log
    ADD CONSTRAINT user_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20190718000001), (20190718002331), (20190718002847), (20190718003511), (20190718004032), (20190724221745), (20190731150948), (20190731151100), (20190806051809), (20190807090748), (20190811203434), (20190916195655), (20190916195840);

