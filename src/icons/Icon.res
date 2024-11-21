let assetUrl = `https://maven.hyperswitch.io/release/production/icons/1.0.0/error.svg`
let card = `<svg class="p-Icon p-Icon--card Icon p-Icon--md p-TabIcon TabIcon p-TabIcon--selected TabIcon--selected" role="presentation" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"><path fill-rule="evenodd" clip-rule="evenodd" d="M0 4a2 2 0 012-2h12a2 2 0 012 2H0zm0 2v6a2 2 0 002 2h12a2 2 0 002-2V6H0zm3 5a1 1 0 011-1h1a1 1 0 110 2H4a1 1 0 01-1-1z"></path></svg>`
let cardv1 = `<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M17.5 3.75H2.5C2.16848 3.75 1.85054 3.8817 1.61612 4.11612C1.3817 4.35054 1.25 4.66848 1.25 5V15C1.25 15.3315 1.3817 15.6495 1.61612 15.8839C1.85054 16.1183 2.16848 16.25 2.5 16.25H17.5C17.8315 16.25 18.1495 16.1183 18.3839 15.8839C18.6183 15.6495 18.75 15.3315 18.75 15V5C18.75 4.66848 18.6183 4.35054 18.3839 4.11612C18.1495 3.8817 17.8315 3.75 17.5 3.75ZM17.5 5V6.875H2.5V5H17.5ZM17.5 15H2.5V8.125H17.5V15ZM16.25 13.125C16.25 13.2908 16.1842 13.4497 16.0669 13.5669C15.9497 13.6842 15.7908 13.75 15.625 13.75H13.125C12.9592 13.75 12.8003 13.6842 12.6831 13.5669C12.5658 13.4497 12.5 13.2908 12.5 13.125C12.5 12.9592 12.5658 12.8003 12.6831 12.6831C12.8003 12.5658 12.9592 12.5 13.125 12.5H15.625C15.7908 12.5 15.9497 12.5658 16.0669 12.6831C16.1842 12.8003 16.25 12.9592 16.25 13.125ZM11.25 13.125C11.25 13.2908 11.1842 13.4497 11.0669 13.5669C10.9497 13.6842 10.7908 13.75 10.625 13.75H9.375C9.20924 13.75 9.05027 13.6842 8.93306 13.5669C8.81585 13.4497 8.75 13.2908 8.75 13.125C8.75 12.9592 8.81585 12.8003 8.93306 12.6831C9.05027 12.5658 9.20924 12.5 9.375 12.5H10.625C10.7908 12.5 10.9497 12.5658 11.0669 12.6831C11.1842 12.8003 11.25 12.9592 11.25 13.125Z" fill="#006DF9"/></svg>`
let close = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16" fill="none"><path d="M13.7429 2.27713C13.3877 1.92197 12.8117 1.92197 12.4618 2.27713L8.01009 6.71659L3.55299 2.26637C3.19771 1.91121 2.62173 1.91121 2.27184 2.26637C1.91656 2.62152 1.91656 3.19731 2.27184 3.54709L6.72356 7.99731L2.26646 12.4529C1.91118 12.8081 1.91118 13.3839 2.26646 13.7336C2.62173 14.0888 3.19771 14.0888 3.5476 13.7336L7.99932 9.28341L12.451 13.7336C12.8063 14.0888 13.3823 14.0888 13.7322 13.7336C14.0875 13.3785 14.0875 12.8027 13.7322 12.4529L9.28047 8.00269L13.7322 3.55247C14.0875 3.20807 14.0875 2.62152 13.7429 2.27713Z" fill="#8D8D8D"/></svg>`
let cvvempty = `<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path opacity="0.3" fill-rule="evenodd" clip-rule="evenodd" d="M5 6C3.89543 6 3 6.89543 3 8V8.37275H21V8C21 6.89543 20.1046 6 19 6H5ZM21 11.0728H3V16.2727C3 17.3773 3.89543 18.2727 5 18.2727H19C20.1046 18.2727 21 17.3773 21 16.2727V11.0728ZM4.15385 15.4616C4.15385 15.3341 4.25717 15.2308 4.38462 15.2308H7.15385C7.2813 15.2308 7.38462 15.3341 7.38462 15.4616C7.38462 15.589 7.2813 15.6923 7.15385 15.6923H4.38462C4.25717 15.6923 4.15385 15.589 4.15385 15.4616ZM4.38462 16.1538C4.25717 16.1538 4.15385 16.2571 4.15385 16.3846C4.15385 16.512 4.25717 16.6154 4.38462 16.6154H9.92308C10.0505 16.6154 10.1538 16.512 10.1538 16.3846C10.1538 16.2571 10.0505 16.1538 9.92308 16.1538H4.38462Z" fill="#979797"/><circle cx="17.0769" cy="12" r="2.76923" fill="#858F97"/><path d="M15.6248 11.3891V12.8914H15.9278V11.1086H15.2308V11.3891H15.6248Z" fill="white"/><path d="M17.4904 12.8889V12.5987H16.7416L17.0667 12.3231C17.3401 12.0914 17.4781 11.9036 17.4781 11.6549C17.4781 11.294 17.2391 11.0769 16.8549 11.0769C16.4732 11.0769 16.222 11.3305 16.2195 11.7207H16.5323C16.5347 11.4915 16.6579 11.3549 16.8549 11.3549C17.0446 11.3549 17.1554 11.4695 17.1554 11.672C17.1554 11.8427 17.0741 11.9597 16.8303 12.1646L16.2417 12.6572V12.8914L17.4904 12.8889Z" fill="white"/><path d="M18.2335 12.0085C18.4847 12.0085 18.6029 12.1402 18.6029 12.3207C18.6029 12.5182 18.4724 12.645 18.2753 12.645C18.0832 12.645 17.9551 12.528 17.9551 12.3231H17.6448C17.6448 12.7084 17.9182 12.9231 18.2704 12.9231C18.6349 12.9231 18.9231 12.6914 18.9231 12.3256C18.9231 12.011 18.7088 11.811 18.4329 11.7573L18.8714 11.3574V11.1086H17.7285V11.3842H18.4773L18.0142 11.8061V12.0085H18.2335Z" fill="white"/></svg>`
let cvvfilled = `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path opacity="0.3" fill-rule="evenodd" clip-rule="evenodd" d="M5 6C3.89543 6 3 6.89543 3 8V8.37275H21V8C21 6.89543 20.1046 6 19 6H5ZM21 11.0728H3V16.2727C3 17.3773 3.89543 18.2727 5 18.2727H19C20.1046 18.2727 21 17.3773 21 16.2727V11.0728ZM4.15385 15.4616C4.15385 15.3341 4.25717 15.2308 4.38462 15.2308H7.15385C7.2813 15.2308 7.38462 15.3341 7.38462 15.4616C7.38462 15.589 7.2813 15.6923 7.15385 15.6923H4.38462C4.25717 15.6923 4.15385 15.589 4.15385 15.4616ZM4.38462 16.1538C4.25717 16.1538 4.15385 16.2571 4.15385 16.3846C4.15385 16.512 4.25717 16.6154 4.38462 16.6154H9.92308C10.0505 16.6154 10.1538 16.512 10.1538 16.3846C10.1538 16.2571 10.0505 16.1538 9.92308 16.1538H4.38462Z" fill="#979797"/><circle cx="17.0769" cy="12" r="2.76923" fill="#006DF9"/><path d="M15.6248 11.3891V12.8914H15.9278V11.1086H15.2308V11.3891H15.6248Z" fill="white"/><path d="M17.4904 12.8889V12.5987H16.7416L17.0667 12.3231C17.3401 12.0914 17.4781 11.9036 17.4781 11.6549C17.4781 11.294 17.2391 11.0769 16.8549 11.0769C16.4732 11.0769 16.2219 11.3305 16.2195 11.7207H16.5323C16.5347 11.4915 16.6579 11.3549 16.8549 11.3549C17.0446 11.3549 17.1554 11.4695 17.1554 11.672C17.1554 11.8427 17.0741 11.9597 16.8303 12.1646L16.2417 12.6572V12.8914L17.4904 12.8889Z" fill="white"/><path d="M18.2334 12.0085C18.4847 12.0085 18.6029 12.1402 18.6029 12.3207C18.6029 12.5182 18.4724 12.645 18.2753 12.645C18.0832 12.645 17.9551 12.528 17.9551 12.3231H17.6448C17.6448 12.7084 17.9182 12.9231 18.2704 12.9231C18.6349 12.9231 18.9231 12.6914 18.9231 12.3256C18.9231 12.011 18.7088 11.811 18.4329 11.7573L18.8714 11.3574V11.1086H17.7285V11.3842H18.4773L18.0142 11.8061V12.0085H18.2334Z" fill="white"/></svg>`
let error = `<?xml version="1.0" encoding="utf-8"?><svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 115.19 123.38" style="enable-background:new 0 0 115.19 123.38" xml:space="preserve"><style type="text/css">.st0{fill-rule:evenodd;clip-rule:evenodd;stroke:#000000;stroke-width:0.5;stroke-miterlimit:2.6131;}</style><g><path class="st0" d="M93.13,79.5c12.05,0,21.82,9.77,21.82,21.82c0,12.05-9.77,21.82-21.82,21.82c-12.05,0-21.82-9.77-21.82-21.82 C71.31,89.27,81.08,79.5,93.13,79.5L93.13,79.5z M8.08,0.25h95.28c2.17,0,4.11,0.89,5.53,2.3c1.42,1.42,2.3,3.39,2.3,5.53v70.01 c-2.46-1.91-5.24-3.44-8.25-4.48V9.98c0-0.43-0.16-0.79-0.46-1.05c-0.26-0.26-0.66-0.46-1.05-0.46H9.94 c-0.43,0-0.79,0.16-1.05,0.46C8.63,9.19,8.43,9.58,8.43,9.98v70.02h0.03l31.97-30.61c1.28-1.18,3.29-1.05,4.44,0.23 c0.03,0.03,0.03,0.07,0.07,0.07l26.88,31.8c-4.73,5.18-7.62,12.08-7.62,19.65c0,3.29,0.55,6.45,1.55,9.4H8.08 c-2.17,0-4.11-0.89-5.53-2.3s-2.3-3.39-2.3-5.53V8.08c0-2.17,0.89-4.11,2.3-5.53S5.94,0.25,8.08,0.25L8.08,0.25z M73.98,79.35 l3.71-22.79c0.3-1.71,1.91-2.9,3.62-2.6c0.66,0.1,1.25,0.43,1.71,0.86l17.1,17.97c-2.18-0.52-4.44-0.79-6.78-0.79 C85.91,71.99,79.13,74.77,73.98,79.35L73.98,79.35z M81.98,18.19c3.13,0,5.99,1.28,8.03,3.32c2.07,2.07,3.32,4.9,3.32,8.03 c0,3.13-1.28,5.99-3.32,8.03c-2.07,2.07-4.9,3.32-8.03,3.32c-3.13,0-5.99-1.28-8.03-3.32c-2.07-2.07-3.32-4.9-3.32-8.03 c0-3.13,1.28-5.99,3.32-8.03C76.02,19.44,78.86,18.19,81.98,18.19L81.98,18.19z M85.82,88.05l19.96,21.6 c1.58-2.39,2.5-5.25,2.5-8.33c0-8.36-6.78-15.14-15.14-15.14C90.48,86.17,87.99,86.85,85.82,88.05L85.82,88.05z M100.44,114.58 l-19.96-21.6c-1.58,2.39-2.5,5.25-2.5,8.33c0,8.36,6.78,15.14,15.14,15.14C95.78,116.46,98.27,115.78,100.44,114.58L100.44,114.58z"/></g></svg>`
let lock = `<svg xmlns="http://www.w3.org/2000/svg" width="8" height="11" viewBox="0 0 8 11" fill="none"><path d="M1 10.5566C0.725 10.5566 0.489666 10.4588 0.294 10.2631C0.0983332 10.0675 0.000333333 9.83197 0 9.55664V4.55664C0 4.28164 0.0979999 4.04631 0.294 3.85064C0.49 3.65497 0.725333 3.55697 1 3.55664H1.5V2.55664C1.5 1.86497 1.74383 1.27547 2.2315 0.788141C2.71917 0.300807 3.30867 0.056974 4 0.0566406C4.69167 0.0566406 5.28133 0.300474 5.769 0.788141C6.25666 1.27581 6.50033 1.86531 6.5 2.55664V3.55664H7C7.275 3.55664 7.5105 3.65464 7.7065 3.85064C7.9025 4.04664 8.00033 4.28197 8 4.55664V9.55664C8 9.83164 7.90216 10.0671 7.7065 10.2631C7.51083 10.4591 7.27533 10.557 7 10.5566H1ZM1 9.55664H7V4.55664H1V9.55664ZM4 8.05664C4.275 8.05664 4.5105 7.95881 4.7065 7.76314C4.9025 7.56747 5.00033 7.33197 5 7.05664C5 6.78164 4.90217 6.54631 4.7065 6.35064C4.51083 6.15497 4.27533 6.05697 4 6.05664C3.725 6.05664 3.48967 6.15464 3.294 6.35064C3.09833 6.54664 3.00033 6.78197 3 7.05664C3 7.33164 3.098 7.56714 3.294 7.76314C3.49 7.95914 3.72533 8.05698 4 8.05664ZM2.5 3.55664H5.5V2.55664C5.5 2.13997 5.35417 1.78581 5.0625 1.49414C4.77083 1.20247 4.41667 1.05664 4 1.05664C3.58333 1.05664 3.22917 1.20247 2.9375 1.49414C2.64583 1.78581 2.5 2.13997 2.5 2.55664V3.55664Z" fill="#434343"/></svg>`
let waitcard = `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M4 5.18182C2.89543 5.18182 2 6.07726 2 7.18183V8.18182H22V7.18182C22 6.07725 21.1046 5.18182 20 5.18182H4ZM22 10.6818H2V16.8182C2 17.9228 2.89543 18.8182 4 18.8182H20C21.1046 18.8182 22 17.9228 22 16.8182V10.6818ZM3.625 13.1818C3.625 12.9747 3.79289 12.8068 4 12.8068H12C12.2071 12.8068 12.375 12.9747 12.375 13.1818C12.375 13.3889 12.2071 13.5568 12 13.5568H4C3.79289 13.5568 3.625 13.3889 3.625 13.1818ZM4 14.8068C3.79289 14.8068 3.625 14.9747 3.625 15.1818C3.625 15.3889 3.79289 15.5568 4 15.5568H8C8.20711 15.5568 8.375 15.3889 8.375 15.1818C8.375 14.9747 8.20711 14.8068 8 14.8068H4Z" fill="#979797"/></svg>`
let camera = `<svg viewBox="0 0 18 16" xmlns="http://www.w3.org/2000/svg"><path d="M4.79203 2.09772H4.83575L4.86544 2.06563L6.37742 0.431055H11.29L12.802 2.06563L12.8316 2.09772H12.8754H15.5004C15.932 2.09772 16.299 2.25023 16.6067 2.55802C16.9145 2.8658 17.067 3.23279 17.067 3.66439V13.6644C17.067 14.096 16.9145 14.463 16.6067 14.7708C16.299 15.0785 15.932 15.2311 15.5004 15.2311H2.16703C1.73543 15.2311 1.36845 15.0785 1.06066 14.7708C0.752875 14.463 0.600366 14.096 0.600366 13.6644V3.66439C0.600366 3.23279 0.752875 2.8658 1.06066 2.55802C1.36845 2.25023 1.73543 2.09772 2.16703 2.09772H4.79203ZM2.06703 13.6644V13.7644H2.16703H15.5004H15.6004V13.6644V3.66439V3.56439H15.5004H12.1695L10.6784 1.93032L10.6487 1.89772H10.6045H7.06287H7.01874L6.989 1.93032L5.49791 3.56439H2.16703H2.06703V3.66439V13.6644ZM11.4192 11.2499C10.709 11.9601 9.84915 12.3144 8.8337 12.3144C7.81825 12.3144 6.95836 11.9601 6.24816 11.2499C5.53796 10.5397 5.1837 9.67984 5.1837 8.66439C5.1837 7.64894 5.53796 6.78905 6.24816 6.07885C6.95836 5.36865 7.81825 5.01439 8.8337 5.01439C9.84915 5.01439 10.709 5.36865 11.4192 6.07885C12.1294 6.78905 12.4837 7.64894 12.4837 8.66439C12.4837 9.67984 12.1294 10.5397 11.4192 11.2499ZM7.28382 10.2143C7.70585 10.6363 8.22456 10.8477 8.8337 10.8477C9.44284 10.8477 9.96155 10.6363 10.3836 10.2143C10.8056 9.79223 11.017 9.27353 11.017 8.66439C11.017 8.05525 10.8056 7.53654 10.3836 7.11451C9.96155 6.69248 9.44284 6.48105 8.8337 6.48105C8.22456 6.48105 7.70585 6.69248 7.28382 7.11451C6.86179 7.53654 6.65037 8.05525 6.65037 8.66439C6.65037 9.27353 6.86179 9.79223 7.28382 10.2143Z" stroke="white" stroke-width="0.2"/></svg>`
let addwithcircle = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M12.7269 7.95376H7.96335V12.7152C7.96335 13.2416 7.53248 13.6663 7.01185 13.6663C6.48522 13.6663 6.06034 13.2357 6.06034 12.7152V7.95376H1.28484C0.75822 7.95376 0.333332 7.52308 0.333332 7.00267C0.333332 6.47627 0.764204 6.05157 1.28484 6.05157H6.04837V1.28411C6.04837 0.757712 6.47924 0.333008 6.99988 0.333008C7.5265 0.333008 7.95139 0.763694 7.95139 1.28411V6.04558H12.7149C13.2415 6.04558 13.6664 6.47627 13.6664 6.99668C13.6784 7.52906 13.2475 7.95376 12.7269 7.95376Z" fill="#006AA8"/></svg>`
let checkboxclicked = `<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18"><path d="M15.9982 0H2.00179C0.904036 0 0 0.904036 0 2.00179V15.9982C0 17.104 0.904036 18 2.00179 18H15.9982C17.096 18 18 17.104 18 15.9982V2.00179C18 0.904036 17.104 0 15.9982 0ZM7.70852 13.2861C7.32108 13.6735 6.69148 13.6735 6.29596 13.2861L2.70404 9.69417C2.31659 9.30673 2.31659 8.67713 2.70404 8.28161C3.09148 7.89417 3.72108 7.89417 4.11659 8.28161L6.99821 11.1632L13.8834 4.2861C14.2709 3.89865 14.9004 3.89865 15.296 4.2861C15.6834 4.67354 15.6834 5.30314 15.296 5.69865L7.70852 13.2861Z"/></svg>`
let checkboxnotclicked = `<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18"><path d="M14.9973 15.9982H3.00269C2.45381 15.9982 2.00179 15.5462 2.00179 14.9973V3.00269C2.00179 2.45381 2.45381 2.00179 3.00269 2.00179H15.0054C15.5543 2.00179 16.0063 2.45381 16.0063 3.00269V15.0054C15.9982 15.5462 15.5462 15.9982 14.9973 15.9982ZM15.9982 0H2.00179C0.904036 0 0 0.904036 0 2.00179V15.9982C0 17.104 0.904036 18 2.00179 18H15.9982C17.096 18 18 17.104 18 15.9982V2.00179C18 0.904036 17.104 0 15.9982 0Z"/></svg>`
let samsungPay = `<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="5 5 750 200"><path d="M0 0 C1.28463327 -0.00465992 2.56926653 -0.00931984 3.89282808 -0.01412097 C7.45853308 -0.02662377 11.02399866 -0.0204838 14.58970472 -0.01128729 C18.46896025 -0.00457805 22.34817457 -0.01524332 26.22742134 -0.02368313 C33.02633942 -0.03606096 39.82518849 -0.03725766 46.62411404 -0.0311327 C56.73433337 -0.02204898 66.84448879 -0.03006774 76.95470321 -0.04142394 C95.0109306 -0.06110432 113.0671293 -0.06343565 131.12336485 -0.05822874 C146.92516649 -0.0536741 162.72695677 -0.05426757 178.52875805 -0.06006908 C180.64720859 -0.06082594 182.76565913 -0.06158193 184.88410966 -0.06233703 C188.07629694 -0.0634822 191.26848421 -0.06463208 194.46067147 -0.06579627 C224.14404197 -0.07650348 253.82740868 -0.08122422 283.51078033 -0.07332611 C284.63005046 -0.07302894 285.74932058 -0.07273176 286.90250798 -0.07242559 C295.99216735 -0.06997657 305.08182667 -0.06736502 314.17148599 -0.06474145 C349.63221288 -0.05463776 385.09289242 -0.06299585 420.55361271 -0.086236 C460.38209063 -0.11229636 500.21054004 -0.12515987 540.0390268 -0.11804825 C544.28409834 -0.11733217 548.52916989 -0.11665779 552.77424145 -0.1160078 C553.81950755 -0.115838 554.86477366 -0.11566819 555.94171449 -0.11549323 C571.73383565 -0.11318836 587.52593038 -0.12117618 603.31804562 -0.13429928 C621.27322913 -0.14919314 639.22835061 -0.15007698 657.18353277 -0.13222837 C667.23530967 -0.12264811 677.286942 -0.12413538 687.33870932 -0.14146306 C694.05015146 -0.15192661 700.7614831 -0.14788881 707.4729143 -0.13198302 C711.29873787 -0.12332388 715.12427744 -0.12099292 718.95008676 -0.13625234 C723.07061309 -0.1525324 727.19045376 -0.13792147 731.31097412 -0.12025452 C732.49953372 -0.12990503 733.68809331 -0.13955554 734.91266987 -0.14949849 C745.09256347 -0.05946285 752.05746051 2.65184417 759.49575138 9.58734798 C765.04721596 15.36540295 767.45975362 21.437612 767.48583317 29.39418697 C767.49436314 30.57582424 767.5028931 31.75746151 767.51168156 32.97490597 C767.51077518 34.25764904 767.50986881 35.54039211 767.50893497 36.86200619 C767.51492462 38.23743713 767.52173116 39.61286472 767.5292902 40.98828793 C767.54691383 44.71364281 767.55164406 48.43890575 767.55292177 52.1642983 C767.55434607 54.49514066 767.55862097 56.82595986 767.56391621 59.15679646 C767.58240495 67.29796863 767.59058833 75.43907543 767.5890131 83.58026791 C767.58781224 91.15340553 767.60890655 98.72625791 767.64050043 106.29932338 C767.6667052 112.81419434 767.67737863 119.32897239 767.67610228 125.84389561 C767.67559385 129.72920343 767.68121075 133.61425764 767.70245838 137.49951267 C767.72191179 141.1563351 767.72191742 144.81266387 767.70742512 148.46950436 C767.70435807 150.43940801 767.72096393 152.40931209 767.73830509 154.37914181 C767.6650296 164.77432162 765.26323401 171.97499154 758.13247013 179.59125423 C748.93735348 188.18587347 738.54099822 188.68021539 726.46994114 188.63199902 C725.20103777 188.6349059 723.93213439 188.63781278 722.6247794 188.64080775 C719.10789441 188.64857917 715.59111957 188.64394474 712.07423642 188.63725184 C708.24612889 188.63217212 704.41803807 188.63870079 700.58993292 188.64373851 C693.88236166 188.65095989 687.17482261 188.65074396 680.46724987 188.64564419 C670.49287625 188.63808126 660.5185298 188.64194565 650.54415636 188.6480608 C632.73025389 188.65859561 614.91636576 188.65767817 597.10246192 188.65190298 C581.51330642 188.64687379 565.92415618 188.64555757 550.33500004 188.64794827 C548.78448564 188.64817742 548.78448564 188.64817742 547.20264772 188.64841121 C543.00672107 188.64903387 538.81079443 188.64967067 534.61486779 188.65033073 C495.24607709 188.65645007 455.87729553 188.65089969 416.50850625 188.64013694 C381.52426926 188.63064558 346.54004683 188.63149483 311.55580997 188.64105892 C272.25946724 188.65176593 232.96313257 188.6560161 193.66678858 188.64983439 C189.47846413 188.64919295 185.29013968 188.64856727 181.10181522 188.64794827 C180.07052713 188.64779011 179.03923903 188.64763196 177.97669977 188.64746901 C162.39654602 188.64519313 146.8163981 188.64785635 131.23624516 188.65290737 C113.52264628 188.65862138 95.80906401 188.65720584 78.09546721 188.64634588 C68.17925317 188.6404671 58.26307506 188.64009892 48.34686194 188.64763823 C41.72582102 188.65211747 35.10480894 188.64934187 28.4837723 188.64062869 C24.70965746 188.63586451 20.93561409 188.63425824 17.16150147 188.64144066 C13.09656603 188.64909774 9.03180605 188.64131121 4.96687412 188.63199902 C3.79464383 188.63668135 2.62241353 188.64136368 1.41466111 188.6461879 C-10.13339085 188.59307642 -18.61906094 186.68296006 -27.46909237 179.06781673 C-35.93612354 169.22775348 -37.08245135 160.10411342 -37.05625057 147.42182064 C-37.0613615 146.13949047 -37.06647243 144.8571603 -37.07173824 143.53597164 C-37.08506045 140.03792226 -37.08571449 136.53998138 -37.08317494 133.0419116 C-37.08210054 130.11224204 -37.0870006 127.18259401 -37.09178036 124.25292909 C-37.10285227 117.33606516 -37.10332614 110.41925554 -37.0972662 103.50238705 C-37.09122884 96.38824359 -37.1035366 89.27429803 -37.12483627 82.16018832 C-37.14250181 76.03252015 -37.14844582 69.9049147 -37.14519852 63.77722204 C-37.14339328 60.12614419 -37.14594536 56.47520752 -37.15991306 52.82415295 C-37.17492347 48.74850702 -37.16547818 44.67325908 -37.15390682 40.59760189 C-37.16155056 39.40247478 -37.1691943 38.20734768 -37.17706966 36.9760046 C-37.11047819 26.33107229 -35.44010067 17.20656738 -27.80502987 9.34516048 C-19.082245 1.0869913 -11.68301538 -0.06609793 0 0 Z " fill="#000000" transform="translate(54.78159236907959,18.619683265686035)"/><path d="M0 0 C7.92 0 15.84 0 24 0 C27.07435787 13.21973883 29.01867589 26.58027534 31 40 C32.74824082 32.63073377 33.95092425 25.23940013 35.0625 17.75 C35.40654238 15.45297354 35.75155737 13.1560925 36.09765625 10.859375 C36.24726807 9.85358398 36.39687988 8.84779297 36.55102539 7.81152344 C36.96950527 5.19096104 37.45990558 2.59792252 38 0 C41.97915159 -0.02886984 45.95827653 -0.04675406 49.9375 -0.0625 C51.07380859 -0.07087891 52.21011719 -0.07925781 53.38085938 -0.08789062 C54.46044922 -0.09111328 55.54003906 -0.09433594 56.65234375 -0.09765625 C58.15269165 -0.10551147 58.15269165 -0.10551147 59.68334961 -0.11352539 C62 0 62 0 63 1 C63.12330088 2.8096774 63.17790183 4.62407837 63.20532227 6.43774414 C63.2352401 8.17943626 63.2352401 8.17943626 63.26576233 9.95631409 C63.28247482 11.219832 63.29918732 12.48334991 63.31640625 13.78515625 C63.33718735 15.07111191 63.35796844 16.35706757 63.37937927 17.68199158 C63.43466176 21.10635904 63.48404361 24.5307875 63.53222656 27.95526123 C63.58239665 31.44744314 63.6381061 34.9395361 63.69335938 38.43164062 C63.80101642 45.28768502 63.90193283 52.1438118 64 59 C59.05 59 54.1 59 49 59 C48.67 42.5 48.34 26 48 9 C47.01 14.61 46.02 20.22 45 26 C44.12697931 30.93786556 43.25246126 35.87542629 42.375 40.8125 C42.1584375 42.03775391 41.941875 43.26300781 41.71875 44.52539062 C41.50992188 45.69908203 41.30109375 46.87277344 41.0859375 48.08203125 C40.9007959 49.12593018 40.7156543 50.1698291 40.52490234 51.24536133 C40.09284222 53.51277266 39.55982298 55.76070808 39 58 C33.72 58 28.44 58 23 58 C20.36 43.48 17.72 28.96 15 14 C14.71063053 28.4353218 14.71063053 28.4353218 14.43188477 42.87084961 C14.39377902 44.67302255 14.35531137 46.47518789 14.31640625 48.27734375 C14.29993042 49.22226685 14.28345459 50.16718994 14.26647949 51.14074707 C14.24629761 52.03394653 14.22611572 52.927146 14.20532227 53.84741211 C14.18977798 54.62684677 14.1742337 55.40628143 14.15821838 56.20933533 C14 58 14 58 13 59 C10.64686445 59.07271741 8.29166332 59.08370868 5.9375 59.0625 C4.64714844 59.05347656 3.35679687 59.04445312 2.02734375 59.03515625 C1.02832031 59.02355469 0.02929688 59.01195312 -1 59 C-1.02497827 52.84765916 -1.04298991 46.69534874 -1.05493164 40.54296875 C-1.05991734 38.45604945 -1.06670831 36.36913356 -1.07543945 34.28222656 C-1.12225266 22.79371505 -1.02554112 11.45053004 0 0 Z " fill="#F7F7F7" transform="translate(193,83)"/><path d="M0 0 C1.8515625 0.796875 1.8515625 0.796875 4.6640625 2.359375 C5.3240625 2.689375 5.9840625 3.019375 6.6640625 3.359375 C6.9940625 2.369375 7.3240625 1.379375 7.6640625 0.359375 C11.6240625 0.359375 15.5840625 0.359375 19.6640625 0.359375 C19.6640625 16.859375 19.6640625 33.359375 19.6640625 50.359375 C15.7040625 50.359375 11.7440625 50.359375 7.6640625 50.359375 C7.1690625 48.379375 7.1690625 48.379375 6.6640625 46.359375 C5.5503125 46.99875 4.4365625 47.638125 3.2890625 48.296875 C-2.41396987 51.57083803 -6.70883132 52.10524594 -13.3359375 51.359375 C-21.83815545 48.65467514 -26.60740672 43.72502425 -31.2109375 36.359375 C-34.04008755 28.80929384 -33.60535917 19.0868017 -30.3359375 11.796875 C-27.58879809 7.09308359 -23.99260812 4.09968216 -19.3359375 1.359375 C-18.41941406 0.79669922 -18.41941406 0.79669922 -17.484375 0.22265625 C-12.313095 -1.85525808 -5.31604568 -1.45791219 0 0 Z " fill="#F9F9F9" transform="translate(617.3359375,93.640625)"/><path d="M0 0 C7.26 0 14.52 0 22 0 C25.05199836 8.68645688 27.54162217 17.44522522 29.89306641 26.34423828 C30.13718262 27.26060059 30.38129883 28.17696289 30.6328125 29.12109375 C30.95596436 30.34977173 30.95596436 30.34977173 31.28564453 31.60327148 C32.03582616 34.12020008 33.02459897 36.56149741 34 39 C34.33 26.13 34.66 13.26 35 0 C39.62 0 44.24 0 49 0 C49 19.14 49 38.28 49 58 C42.07 58 35.14 58 28 58 C24.22403758 46.89422817 20.53626146 35.84586202 17.51098633 24.51220703 C16.51247021 20.66349196 16.51247021 20.66349196 15 17 C14.67 30.53 14.34 44.06 14 58 C9.38 58 4.76 58 0 58 C0 38.86 0 19.72 0 0 Z " fill="#FDFDFD" transform="translate(383,83)"/><path d="M0 0 C30.8490566 0 30.8490566 0 38.4375 7.3125 C43.29099496 13.80215898 45.09698432 19.98066635 44 28 C42.12118607 34.56994054 37.63474199 39.29029442 32 43 C27.35341424 44.99514417 23.10702726 45.24952313 18.125 45.125 C15.77375 45.08375 13.4225 45.0425 11 45 C11 50.94 11 56.88 11 63 C7.37 63 3.74 63 0 63 C0 42.21 0 21.42 0 0 Z " fill="#FBFBFB" transform="translate(539,81)"/><path d="M0 0 C5.24666064 5.3811904 5 8.43972474 5 16 C0.05 16 -4.9 16 -10 16 C-10.66 13.36 -11.32 10.72 -12 8 C-15.40320934 7.32326553 -15.40320934 7.32326553 -19 7 C-21.48850674 9.48850674 -21.2461233 10.9621006 -21.27789307 14.35913086 C-21.2738446 15.08624268 -21.26979614 15.81335449 -21.265625 16.5625 C-21.26849518 17.68313843 -21.26849518 17.68313843 -21.27142334 18.82641602 C-21.27278498 20.40674171 -21.26909 21.98707858 -21.26074219 23.56738281 C-21.250042 25.99048922 -21.26063779 28.41285423 -21.2734375 30.8359375 C-21.2721159 32.36979331 -21.2695535 33.90364865 -21.265625 35.4375 C-21.26967346 36.16461182 -21.27372192 36.89172363 -21.27789307 37.64086914 C-21.36731502 41.77469633 -21.36731502 41.77469633 -19 45 C-14.65805064 44.90304884 -14.65805064 44.90304884 -11 43 C-10.76572222 40.98405418 -10.58663876 38.961526 -10.4375 36.9375 C-10.35371094 35.83277344 -10.26992188 34.72804687 -10.18359375 33.58984375 C-10.09271484 32.30787109 -10.09271484 32.30787109 -10 31 C-11.98 31 -13.96 31 -16 31 C-16 28.03 -16 25.06 -16 22 C-9.07 22 -2.14 22 5 22 C5.08118636 25.54213083 5.14059277 29.08238743 5.1875 32.625 C5.21263672 33.62402344 5.23777344 34.62304688 5.26367188 35.65234375 C5.31877642 41.19953438 5.20729089 45.24566291 2 50 C-3.36735937 55.36735937 -8.41923649 57.03550569 -15.875 57.3125 C-22.4556361 57.15224098 -27.83075849 55.80000891 -32.9375 51.5625 C-36.87610271 46.66908451 -37.3081376 42.94043869 -37.30078125 36.7265625 C-37.30506638 35.92519867 -37.3093515 35.12383484 -37.31376648 34.29818726 C-37.31950053 32.60537662 -37.32001685 30.91254134 -37.31567383 29.21972656 C-37.31251938 26.640844 -37.33596427 24.06311537 -37.36132812 21.484375 C-37.3636019 19.83593894 -37.36430425 18.18749981 -37.36328125 16.5390625 C-37.372491 15.7732486 -37.38170074 15.00743469 -37.39118958 14.21841431 C-37.34438232 8.75222033 -36.29169871 4.57281375 -32.53515625 0.35546875 C-23.91226684 -6.48337457 -8.89887846 -6.33189429 0 0 Z " fill="#F9F9F9" transform="translate(484,86)"/><path d="M0 0 C4.95 0 9.9 0 15 0 C15.02505615 1.41853271 15.0501123 2.83706543 15.07592773 4.29858398 C15.16980881 9.54103271 15.27007589 14.78334291 15.37231445 20.02563477 C15.41573665 22.29838836 15.45740616 24.57117613 15.49731445 26.84399414 C15.55484119 30.10313232 15.61858552 33.36209731 15.68359375 36.62109375 C15.70030624 37.64400009 15.71701874 38.66690643 15.73423767 39.72080994 C15.75418289 40.66170975 15.77412811 41.60260956 15.79467773 42.57202148 C15.81022202 43.40475082 15.8257663 44.23748016 15.84178162 45.09544373 C15.79428614 47.00966585 15.79428614 47.00966585 17 48 C19.33297433 48.04092937 21.66705225 48.04241723 24 48 C25.17559215 45.6488157 25.15516463 44.17282086 25.20532227 41.55029297 C25.22526749 40.62948944 25.24521271 39.70868591 25.26576233 38.75997925 C25.28247482 37.76410797 25.29918732 36.76823669 25.31640625 35.7421875 C25.33718735 34.72399933 25.35796844 33.70581116 25.37937927 32.6567688 C25.44489466 29.39624945 25.50376902 26.13564794 25.5625 22.875 C25.60568332 20.66796017 25.64929755 18.46092872 25.69335938 16.25390625 C25.8005781 10.83602225 25.90183996 5.41805539 26 0 C30.95 0 35.9 0 41 0 C41.09911712 6.85013643 41.1715874 13.69985239 41.21972656 20.55053711 C41.23980146 22.87938715 41.26706736 25.20818705 41.30175781 27.53686523 C41.35045591 30.89058838 41.37301065 34.24364317 41.390625 37.59765625 C41.41127014 38.63334244 41.43191528 39.66902863 41.45318604 40.73609924 C41.45513406 47.05806998 40.77127352 50.86179099 37 56 C29.94557049 61.29082213 21.41787471 60.48683818 13 60 C8.63681038 59.17418021 5.75179222 57.75179222 2.5625 54.5625 C0.22881374 50.73525453 -0.12520133 47.5765072 -0.11352539 43.13964844 C-0.11344986 42.17895447 -0.11337433 41.2182605 -0.11329651 40.22845459 C-0.10813522 39.19915833 -0.10297394 38.16986206 -0.09765625 37.109375 C-0.0962413 36.04962463 -0.09482635 34.98987427 -0.09336853 33.89801025 C-0.08777382 30.51531138 -0.07522225 27.13267885 -0.0625 23.75 C-0.05748432 21.45573012 -0.05292153 19.16145921 -0.04882812 16.8671875 C-0.03780611 11.24476613 -0.02054507 5.62239431 0 0 Z " fill="#FCFCFC" transform="translate(326,83)"/><path d="M0 0 C3.92414772 2.0972633 6.06995927 4.21555831 7.875 8.375 C8.17293362 11.46038033 8.06371621 14.2611825 7.875 17.375 C2.925 17.375 -2.025 17.375 -7.125 17.375 C-7.785 15.065 -8.445 12.755 -9.125 10.375 C-11.435 10.375 -13.745 10.375 -16.125 10.375 C-16.96287121 13.61710519 -16.96287121 13.61710519 -16.125 17.375 C-13.11243862 19.92064634 -9.61109684 21.56019261 -6.125 23.375 C6.70406385 30.79259277 6.70406385 30.79259277 8.875 36.375 C9.46939948 42.64393316 9.78865932 48.64644947 6.875 54.375 C0.05503243 60.8918579 -5.32924804 61.85345758 -14.5390625 61.6796875 C-20.47313378 61.17548537 -25.51333131 59.94521363 -29.84765625 55.6796875 C-33.68020807 50.40592538 -33.56624281 45.72889647 -33.125 39.375 C-27.845 39.375 -22.565 39.375 -17.125 39.375 C-16.795 42.675 -16.465 45.975 -16.125 49.375 C-12.12245544 49.46681134 -12.12245544 49.46681134 -8.125 49.375 C-6.75863845 48.21633079 -6.75863845 48.21633079 -6.75 45.0625 C-6.72541576 41.33145337 -6.72541576 41.33145337 -9.17578125 39.421875 C-13.20358631 36.62641824 -17.41031705 34.21298957 -21.68554688 31.81835938 C-26.51851261 29.01572497 -29.53167392 26.03054346 -32.4375 21.1875 C-33.73467696 15.88086699 -32.97747606 10.55354993 -31 5.5 C-23.55423436 -2.93853439 -10.060796 -4.04108639 0 0 Z " fill="#F8F8F8" transform="translate(114.125,82.625)"/><path d="M0 0 C8.91 0 17.82 0 27 0 C28.10402514 5.76147075 29.20715465 11.52309915 30.30810547 17.28515625 C30.68194583 19.24033169 31.05628357 21.1954121 31.43115234 23.15039062 C37 52.1975 37 52.1975 37 59 C31.72 59 26.44 59 21 59 C17.535 35.24 17.535 35.24 14 11 C12.4421938 12.5578062 12.56026171 14.27094288 12.24389648 16.42797852 C12.10382675 17.36887833 11.96375702 18.30977814 11.81944275 19.27919006 C11.67148758 20.30209641 11.52353241 21.32500275 11.37109375 22.37890625 C11.21713638 23.42070541 11.06317902 24.46250458 10.90455627 25.53587341 C10.41164403 28.87752273 9.92451566 32.21998672 9.4375 35.5625 C9.1051971 37.82232145 8.77251978 40.08208787 8.43945312 42.34179688 C7.62194928 47.89390109 6.80963317 53.44674281 6 59 C0.72 59 -4.56 59 -10 59 C-9.44120024 49.33685291 -8.04973144 40.10096162 -6.125 30.625 C-5.74021484 28.68367188 -5.74021484 28.68367188 -5.34765625 26.703125 C-4.70482113 23.4663371 -4.05575953 20.23090581 -3.40246582 16.99621582 C-2.69882187 13.50616743 -2.00224922 10.01470557 -1.3046875 6.5234375 C-0.87414062 4.37070313 -0.44359375 2.21796875 0 0 Z " fill="#F7F7F7" transform="translate(143,83)"/><path d="M0 0 C0.80759766 -0.02384766 1.61519531 -0.04769531 2.44726562 -0.07226562 C8.48360221 -0.05767335 13.04124598 1.44734254 17.5625 5.5625 C20.33182925 10.16611118 19.70126107 14.28957937 19.5625 19.5625 C14.9425 19.5625 10.3225 19.5625 5.5625 19.5625 C4.5725 16.9225 3.5825 14.2825 2.5625 11.5625 C0.56295254 11.51995644 -1.43791636 11.52169217 -3.4375 11.5625 C-4.69195974 12.61018699 -4.69195974 12.61018699 -4.71484375 14.9375 C-4.69059689 17.59176161 -4.69059689 17.59176161 -3.00390625 19.1875 C-2.34261719 19.64125 -1.68132812 20.095 -1 20.5625 C-0.27167969 21.06652344 0.45664062 21.57054688 1.20703125 22.08984375 C4.22032007 23.97377391 7.31956823 25.65880521 10.44921875 27.33984375 C14.63013599 29.75874781 17.86353302 32.51404953 20.5625 36.5625 C20.8984375 39.92578125 20.8984375 39.92578125 20.9375 43.875 C20.96585937 45.17050781 20.99421875 46.46601562 21.0234375 47.80078125 C20.47906863 52.24338482 19.49439117 54.19889023 16.5625 57.5625 C11.08687152 61.62856076 6.77394816 62.18973124 0.0625 62.0625 C-0.75347656 62.07796875 -1.56945312 62.0934375 -2.41015625 62.109375 C-8.22959656 62.07201102 -11.6513896 60.88309598 -16.4375 57.5625 C-21.16822707 52.35870022 -20.5243219 47.24778646 -20.4375 40.5625 C-15.4875 40.5625 -10.5375 40.5625 -5.4375 40.5625 C-5.2421875 42.58072917 -5.046875 44.59895833 -4.8515625 46.6171875 C-4.57375251 48.78918245 -4.57375251 48.78918245 -2.4375 50.5625 C0.5625 50.89583333 0.5625 50.89583333 3.5625 50.5625 C5.81445569 48.74440523 5.81445569 48.74440523 5.75 46.125 C5.65945513 43.44310897 5.65945513 43.44310897 4.5625 40.5625 C2.78115062 39.46763337 2.78115062 39.46763337 0.5625 38.5625 C-7.15690306 34.69081182 -15.10881791 30.69421822 -19.9375 23.25 C-21.00070133 17.53529284 -21.3524739 12.53884362 -18.875 7.1875 C-13.21516865 1.09229701 -8.00098338 -0.10803552 0 0 Z " fill="#F9F9F9" transform="translate(291.4375,81.4375)"/><path d="M0 0 C4.29 0 8.58 0 13 0 C14.71577309 4.0722992 16.42456771 8.14743388 18.12695312 12.2253418 C18.70707279 13.61221066 19.28909253 14.99828632 19.87304688 16.38354492 C20.71204306 18.374734 21.54416662 20.36867484 22.375 22.36328125 C23.12910156 24.16212769 23.12910156 24.16212769 23.8984375 25.99731445 C25 29 25 29 25 32 C25.66 32 26.32 32 27 32 C27.11859375 31.13415283 27.2371875 30.26830566 27.359375 29.3762207 C27.99857118 26.00753015 28.96890663 23.15558367 30.25 19.98046875 C30.6934375 18.87638672 31.136875 17.77230469 31.59375 16.63476562 C32.0578125 15.49716797 32.521875 14.35957031 33 13.1875 C33.4640625 12.03056641 33.928125 10.87363281 34.40625 9.68164062 C37.85498768 1.14501232 37.85498768 1.14501232 39 0 C41.01964199 -0.07244053 43.04167124 -0.08377188 45.0625 -0.0625 C46.71958984 -0.04896484 46.71958984 -0.04896484 48.41015625 -0.03515625 C49.26480469 -0.02355469 50.11945312 -0.01195313 51 0 C48.88453418 6.64577739 46.42742368 13.10515099 43.796875 19.5625 C43.3959967 20.55266113 42.99511841 21.54282227 42.58209229 22.56298828 C41.30730795 25.70971198 40.02866847 28.85485293 38.75 32 C37.90730932 34.07932872 37.06485946 36.15875504 36.22265625 38.23828125 C31.52001579 49.84134085 26.78292315 61.42980627 22 73 C18.04 73 14.08 73 10 73 C11.98312498 65.72854175 14.6634543 59.08930095 17.890625 52.296875 C19.98528931 46.07188671 17.34093901 41.00067004 14.7265625 35.29296875 C14.40215179 34.56813797 14.07774109 33.84330719 13.74349976 33.09651184 C12.71057685 30.79048348 11.66857587 28.48872477 10.625 26.1875 C2.36216608 7.90694523 2.36216608 7.90694523 0 0 Z " fill="#F9F9F9" transform="translate(641,94)"/><path d="M0 0 C3.96324195 1.3467058 6.34781786 4.00862009 9.1887207 6.95336914 C9.78093918 7.55124741 10.37315765 8.14912567 10.98332214 8.76512146 C12.86739414 10.67153306 14.73706099 12.5913948 16.60668945 14.51196289 C17.88375799 15.80909942 19.16174284 17.10533451 20.44067383 18.40063477 C23.56922997 21.57322626 26.68494135 24.75795117 29.79418945 27.94946289 C28.13364214 32.515968 26.23920992 34.68098925 22.54418945 37.88696289 C18.90629781 41.07299482 15.39805929 44.3067023 12.0637207 47.81274414 C11.1370459 48.78062866 11.1370459 48.78062866 10.19165039 49.76806641 C8.98353631 51.03967238 7.78715207 52.32254314 6.60375977 53.6171875 C5.06159995 55.2267776 3.6232998 56.67521494 1.79418945 57.94946289 C-1.82150746 57.97499747 -2.81807245 57.29528336 -5.51831055 54.88696289 C-6.35362305 53.92790039 -6.35362305 53.92790039 -7.20581055 52.94946289 C-5.69204973 49.38182004 -3.60067926 47.11240002 -0.85424805 44.40258789 C-0.0034668 43.55825195 0.84731445 42.71391602 1.72387695 41.84399414 C2.61333008 40.97129883 3.5027832 40.09860352 4.41918945 39.19946289 C5.31637695 38.31129883 6.21356445 37.42313477 7.13793945 36.50805664 C9.35225949 34.3172932 11.5711138 32.13133526 13.79418945 29.94946289 C12.28042864 26.38182004 10.18905816 24.11240002 7.44262695 21.40258789 C6.5918457 20.55825195 5.74106445 19.71391602 4.86450195 18.84399414 C3.53032227 17.53495117 3.53032227 17.53495117 2.16918945 16.19946289 C0.8234082 14.8672168 0.8234082 14.8672168 -0.54956055 13.50805664 C-2.76388059 11.3172932 -4.9827349 9.13133526 -7.20581055 6.94946289 C-3.78243857 -0.08665908 -3.78243857 -0.08665908 0 0 Z " fill="#FBFBFB" transform="translate(730.205810546875,83.050537109375)"/><path d="M0 0 C4.29208615 2.35569204 7.14600724 5.46801769 9 10 C9.88266466 14.94292212 9.38108662 19.00747926 6.875 23.375 C4.39705371 26.86918268 2.15568132 28.67018198 -2 30 C-7.24602726 30.56207435 -10.5772872 29.88437792 -15 27 C-18.73122127 23.31906473 -20.7538713 20.09209394 -21.375 14.8125 C-20.79784368 8.94474407 -18.12485798 4.99986633 -13.875 1 C-9.22324427 -0.61800199 -4.85070348 -0.86743625 0 0 Z " fill="#030303" transform="translate(617,104)"/><path d="M0 0 C11.00436681 -0.48908297 11.00436681 -0.48908297 15.5625 1.75 C20.81877023 6.60194175 20.81877023 6.60194175 21.4375 11.375 C20.91706473 15.68717793 19.82101905 17.7215184 17 21 C13.14647904 22.98697174 9.98626866 23.21947843 5.6875 23.125 C3.810625 23.08375 1.93375 23.0425 0 23 C0 15.41 0 7.82 0 0 Z " fill="#0C0C0C" transform="translate(550,92)"/></svg>`

type uri = {
  uri: string,
  local: bool,
}

open ReactNative
open Style
@react.component
let make = (
  ~name,
  ~width=20.,
  ~height=16.,
  ~fill="#ffffff",
  ~defaultView: option<React.element>=?,
  ~style=viewStyle(),
) => {
  defaultView->ignore
  let (isLoaded, setIsLoaded) = React.useState(_ => false)
  let (iconName, setIconName) = React.useState(_ => name->String.toLowerCase)

  React.useEffect1(() => {
    setIconName(_ => name->String.toLowerCase)
    None
  }, [name])

  let uri = React.useMemo1(() => {
    let localName = switch iconName {
    | "card" => card
    | "cardv1" => cardv1
    | "close" => close
    | "cvvempty" => cvvempty
    | "cvvfilled" => cvvfilled
    | "error" => error
    | "lock" => lock
    | "waitcard" => waitcard
    | "camera" => camera
    | "addwithcircle" => addwithcircle
    | "checkboxclicked" => checkboxclicked
    | "checkboxnotclicked" => checkboxnotclicked
    | "samsung_pay" => samsungPay
    | _ => ""
    }
    localName == ""
      ? {
          uri: assetUrl->String.replace("error", iconName),
          local: false,
        }
      : {uri: localName, local: true}
  }, [iconName])

  <View style={array([viewStyle(~height=height->dp, ~width=width->dp, ()), style])}>
    {uri.local
      ? <ReactNativeSvg.SvgCss
          onError={() => {
            setIsLoaded(_ => true)
            setIconName(_ => "error")
          }}
          onLoad={() => {
            setIsLoaded(_ => true)
          }}
          xml=uri.uri
          width
          height
          fill
        />
      : <ReactNativeSvg.SvgUri
          onError={() => {
            setIsLoaded(_ => true)
            setIconName(_ => "error")
          }}
          onLoad={() => {
            setIsLoaded(_ => true)
          }}
          uri=uri.uri
          width
          height
          fill
        />}
    {isLoaded || uri.local
      ? React.null
      : <ActivityIndicator
          style={viewStyle(~height=height->dp, ~width=width->dp, ())} color=fill
        />}
  </View>
}
