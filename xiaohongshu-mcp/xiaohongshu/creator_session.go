package xiaohongshu

import (
	"strings"
	"time"

	"github.com/go-rod/rod"
	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
	"github.com/xpzouying/xiaohongshu-mcp/humanize"
)

const (
	urlOfCreatorHome = `https://creator.xiaohongshu.com/?source=official`

	creatorSessionCookie  = "galaxy_creator_session_id"
	creatorSessionTimeout = 15 * time.Second

	// 创作者中心新版本不再下发 galaxy_creator_session_id，
	// 直接复用主站 SSO 的 web_session / id_token，所以这几个都视为已登录。
	creatorSSOWebSession = "web_session"
	creatorSSOIdToken    = "id_token"

	// cookie 名字再变时用页面内容兜底，避免又被过期的判断条件卡死。
	creatorPageMarker = "发布笔记"
)

// ensureCreatorSession 浏览器里没有创作者中心会话时，先打开创作者中心首页，等会话建立。
// 判断顺序：cookie 名命中 → 页面内容命中（cookie 改名时兜底）。
func ensureCreatorSession(page *rod.Page) error {
	if hasCreatorSession(page) {
		return nil
	}

	if err := page.Navigate(urlOfCreatorHome); err != nil {
		return errors.Wrap(err, "打开创作者中心失败")
	}

	deadline := time.Now().Add(creatorSessionTimeout)
	for time.Now().Before(deadline) {
		time.Sleep(500 * time.Millisecond)
		if hasCreatorSession(page) || isCreatorPageLoggedIn(page) {
			humanize.Delay(page.GetContext(), humanize.AfterNavigate)
			return nil
		}
	}

	return errors.Errorf("创作者中心登录失效，请重新扫码登录（当前页面: %s, cookies: %s）",
		currentURL(page), strings.Join(cookieNames(page), ","))
}

// VerifyCreatorSession 主动打开创作者中心，确认页面真的处于登录态。
// 与 ensureCreatorSession 不同：这里优先看页面，不看 cookie，供 check_login_status 用。
func VerifyCreatorSession(page *rod.Page) error {
	if err := page.Navigate(urlOfCreatorHome); err != nil {
		return errors.Wrap(err, "打开创作者中心失败")
	}

	deadline := time.Now().Add(creatorSessionTimeout)
	for time.Now().Before(deadline) {
		time.Sleep(500 * time.Millisecond)
		if isCreatorPageLoggedIn(page) {
			return nil
		}
	}

	u := currentURL(page)
	// 页面结构变化兜底：只要没被踢到登录页，且仍持有主站会话，就认为可用
	if strings.Contains(u, "creator.xiaohongshu.com") && !strings.Contains(u, "/login") && hasCreatorSession(page) {
		logrus.Warnf("创作者中心未匹配到页面标志，按 cookie 兜底判定为已登录, url=%q", u)
		return nil
	}
	return errors.Errorf("创作者中心未登录（当前页面: %s）", u)
}

func hasCreatorSession(page *rod.Page) bool {
	for _, name := range cookieNames(page) {
		switch name {
		case creatorSessionCookie, creatorSSOWebSession, creatorSSOIdToken:
			return true
		}
	}
	return false
}

// isCreatorPageLoggedIn 用页面本身判断是否已登录创作者中心
func isCreatorPageLoggedIn(page *rod.Page) bool {
	u := currentURL(page)
	if !strings.Contains(u, "creator.xiaohongshu.com") || strings.Contains(u, "/login") {
		return false
	}
	res, err := page.Eval(`() => (document.body && document.body.innerText) || ""`)
	if err != nil {
		return false
	}
	text := res.Value.String()
	return strings.Contains(text, creatorPageMarker) || strings.Contains(text, "笔记管理")
}

func currentURL(page *rod.Page) string {
	info, err := page.Info()
	if err != nil {
		return "<unknown>"
	}
	return info.URL
}

func cookieNames(page *rod.Page) []string {
	cks, err := page.Browser().GetCookies()
	if err != nil {
		return nil
	}
	names := make([]string, 0, len(cks))
	for _, c := range cks {
		names = append(names, c.Name)
	}
	return names
}
