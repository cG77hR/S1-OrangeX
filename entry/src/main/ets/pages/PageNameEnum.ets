import { AboutApp } from './NavDest/AboutApp';
import { BlockListPage } from './NavDest/BlockList';
import { DraftPage } from './NavDest/DraftPage';
import { FavoriteList } from './NavDest/FavoriteList';
import { NoteList } from './NavDest/NoteList';
import { PollDetail } from './NavDest/PollDetail';
import { PostRatingDetail } from './NavDest/PostRatingDetail';
import { PreferencePage } from './NavDest/Preferences';
import { PrivateMessageViewer } from './NavDest/PrivateMessage';
import { PmDetail } from './NavDest/PrivateMessageDetail';
import { SearchPage } from './NavDest/SearchPage';
import { SplitModeShortcut } from './NavDest/SplitModeShortcut';
import { ThreadPostList } from './NavDest/ThreadPostList';
import { UserGuide } from './NavDest/UserGuide';
import { UserSpace } from './NavDest/UserSpace';
import { UserThread } from './NavDest/UserThread';
import { ViewHistory } from './NavDest/ViewHistory';
import { WriteReply } from './NavDest/WriteReply';
import { ReportPost } from './NavDest/ReportPost';
import { DarkRoomPage } from './NavDest/DarkRoom';
import { PageSearchPage } from './NavDest/ThreadPostSearch';
import { LongScreenshotPage } from './NavDest/LongScreenshot';
import { FreeCopy } from './NavDest/FreeCopy';
import { WriteReplyPreview } from './NavDest/WriteReplyPreview';

/**
 * 页面名称。需要对应resources/base/profile/route_map.json内的name。
 */
export enum PageNameEnum {
  ThreadPostList = 'ThreadPostList',
  UserSpace = 'UserSpace',
  Preferences = 'Preferences',
  ImageViewer = 'ImageViewer',
  ViewHistory = 'ViewHistory',
  LoginInWeb = 'LoginInWeb',
  FavoriteList = 'FavoriteList',
  PostRatingDetail = 'PostRatingDetail',
  PollDetail = "PollDetail",
  WriteReply = 'WriteReply',
  SearchPage = "SearchPage",
  UserThread = "UserThread",
  DraftPage = "DraftPage",
  PrivateMessage = "PrivateMessage",
  PmDetail = "PmDetail",
  NoteList = "NoteList",
  BlockList = "BlockList",
  AboutApp = "AboutApp",
  SplitModeShortcut = "SplitModeShortcut",
  UserGuide = "UserGuide",
  ReportPost = "ReportPost",
  DarkRoom = "DarkRoom",
  PageSearch = "PageSearch",
  LongScreenshot = "LongScreenshot",
  FreeCopy = "FreeCopy",
  WriteReplyPreview = "WriteReplyPreview"
}

@Builder
export function buildNavDestPage(name: string) {
  if (name == PageNameEnum.AboutApp) {
    AboutApp()
  } else if (name == PageNameEnum.ThreadPostList) {
    ThreadPostList()
  } else if (name == PageNameEnum.UserSpace) {
    UserSpace()
  } else if (name == PageNameEnum.Preferences) {
    PreferencePage()
  } else if (name == PageNameEnum.ViewHistory) {
    ViewHistory()
  } else if (name == PageNameEnum.FavoriteList) {
    FavoriteList()
  } else if (name == PageNameEnum.PostRatingDetail) {
    PostRatingDetail()
  } else if (name == PageNameEnum.PollDetail) {
    PollDetail()
  } else if (name == PageNameEnum.WriteReply) {
    WriteReply()
  } else if (name == PageNameEnum.SearchPage) {
    SearchPage()
  } else if (name == PageNameEnum.UserThread) {
    UserThread()
  } else if (name == PageNameEnum.DraftPage) {
    DraftPage()
  } else if (name == PageNameEnum.PrivateMessage) {
    PrivateMessageViewer()
  } else if (name == PageNameEnum.PmDetail) {
    PmDetail()
  } else if (name == PageNameEnum.NoteList) {
    NoteList()
  } else if (name == PageNameEnum.BlockList) {
    BlockListPage()
  } else if (name == PageNameEnum.SplitModeShortcut) {
    SplitModeShortcut()
  } else if (name == PageNameEnum.UserGuide) {
    UserGuide()
  } else if (name == PageNameEnum.ReportPost) {
    ReportPost()
  } else if (name == PageNameEnum.DarkRoom) {
    DarkRoomPage()
  } else if (name == PageNameEnum.PageSearch) {
    PageSearchPage()
  } else if (name == PageNameEnum.LongScreenshot) {
    LongScreenshotPage()
  } else if (name == PageNameEnum.FreeCopy) {
    FreeCopy()
  } else if (name == PageNameEnum.WriteReplyPreview) {
    WriteReplyPreview()
  }
}
