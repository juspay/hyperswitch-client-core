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
let defaultTick = `<svg width="14" height="15" viewBox="0 0 14 15" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M7 0.5C3.13901 0.5 0 3.63901 0 7.5C0 11.361 3.13901 14.5 7 14.5C10.861 14.5 14 11.361 14 7.5C14 3.63901 10.861 0.5 7 0.5ZM5.09776 10.4946L2.57399 7.97713C2.29148 7.69462 2.29148 7.24888 2.57399 6.99776C2.8565 6.71525 3.27085 6.71525 3.55336 6.99776L5.56861 9.013L10.3839 4.19776C10.6664 3.91525 11.087 3.91525 11.3632 4.19776C11.6457 4.48027 11.6457 4.9009 11.3632 5.17713L6.04574 10.4946C5.82601 10.7771 5.37399 10.7771 5.09776 10.4946Z" fill="#8DBD00"/></svg>`
let google_pay = `<svg width="752" height="400" viewBox="0 0 752 400" fill="none" xmlns="http://www.w3.org/2000/svg"> <g clip-path="url(#clip0_1_67)">  <path d="M551.379 0H200.022C90.2234 0 0.387924 90 0.387924 200C0.387924 310 90.2234 400 200.022 400H551.379C661.178 400 751.013 310 751.013 200C751.013 90 661.178 0 551.379 0Z" fill="white"/> <path d="M551.379 16.2C576.034 16.2 599.99 21.1 622.548 30.7C644.408 40 663.973 53.3 680.941 70.2C697.811 87.1 711.086 106.8 720.369 128.7C729.952 151.3 734.843 175.3 734.843 200C734.843 224.7 729.952 248.7 720.369 271.3C711.086 293.2 697.811 312.8 680.941 329.8C664.072 346.7 644.408 360 622.548 369.3C599.99 378.9 576.034 383.8 551.379 383.8H200.022C175.367 383.8 151.411 378.9 128.853 369.3C106.993 360 87.4285 346.7 70.4596 329.8C53.5905 312.9 40.3148 293.2 31.0318 271.3C21.4493 248.7 16.5583 224.7 16.5583 200C16.5583 175.3 21.4493 151.3 31.0318 128.7C40.3148 106.8 53.5905 87.2 70.4596 70.2C87.3287 53.3 106.993 40 128.853 30.7C151.411 21.1 175.367 16.2 200.022 16.2H551.379ZM551.379 0H200.022C90.2234 0 0.387924 90 0.387924 200C0.387924 310 90.2234 400 200.022 400H551.379C661.178 400 751.013 310 751.013 200C751.013 90 661.178 0 551.379 0Z" fill="#3C4043"/>  <path d="M358.332 214.2V274.7H339.167V125.3H389.974C402.851 125.3 413.831 129.6 422.814 138.2C431.997 146.8 436.589 157.3 436.589 169.7C436.589 182.4 431.997 192.9 422.814 201.4C413.931 209.9 402.951 214.1 389.974 214.1H358.332V214.2ZM358.332 143.7V195.8H390.374C397.96 195.8 404.348 193.2 409.339 188.1C414.43 183 417.025 176.8 417.025 169.8C417.025 162.9 414.43 156.8 409.339 151.7C404.348 146.4 398.06 143.8 390.374 143.8H358.332V143.7Z" fill="#3C4043"/> <path d="M486.697 169.1C500.871 169.1 512.051 172.9 520.236 180.5C528.421 188.1 532.513 198.5 532.513 211.7V274.7H514.247V260.5H513.448C505.563 272.2 494.982 278 481.806 278C470.527 278 461.144 274.7 453.558 268C445.972 261.3 442.179 253 442.179 243C442.179 232.4 446.171 224 454.157 217.8C462.142 211.5 472.823 208.4 486.098 208.4C497.477 208.4 506.86 210.5 514.147 214.7V210.3C514.147 203.6 511.552 198 506.261 193.3C500.971 188.6 494.782 186.3 487.695 186.3C477.015 186.3 468.531 190.8 462.342 199.9L445.473 189.3C454.756 175.8 468.531 169.1 486.697 169.1ZM461.943 243.3C461.943 248.3 464.039 252.5 468.331 255.8C472.523 259.1 477.514 260.8 483.204 260.8C491.289 260.8 498.476 257.8 504.764 251.8C511.053 245.8 514.247 238.8 514.247 230.7C508.258 226 499.973 223.6 489.292 223.6C481.507 223.6 475.019 225.5 469.828 229.2C464.538 233.1 461.943 237.8 461.943 243.3Z" fill="#3C4043"/>  <path d="M636.723 172.4L572.84 319.6H553.076L576.832 268.1L534.709 172.4H555.571L585.916 245.8H586.315L615.861 172.4H636.723Z" fill="#3C4043"/> <path d="M282.102 202C282.102 195.74 281.543 189.75 280.505 183.99H200.172V216.99L246.437 217C244.561 227.98 238.522 237.34 229.269 243.58V264.99H256.808C272.889 250.08 282.102 228.04 282.102 202Z" fill="#4285F4"/>  <path d="M229.279 243.58C221.613 248.76 211.741 251.79 200.192 251.79C177.883 251.79 158.957 236.73 152.18 216.43H123.772V238.51C137.846 266.49 166.773 285.69 200.192 285.69C223.29 285.69 242.694 278.08 256.818 264.98L229.279 243.58Z" fill="#34A853"/> <path d="M149.505 200.05C149.505 194.35 150.453 188.84 152.18 183.66V161.58H123.772C117.953 173.15 114.679 186.21 114.679 200.05C114.679 213.89 117.963 226.95 123.772 238.52L152.18 216.44C150.453 211.26 149.505 205.75 149.505 200.05Z" fill="#FABB05"/> <path d="M200.192 148.3C212.799 148.3 224.088 152.65 233.002 161.15L257.407 136.72C242.584 122.89 223.26 114.4 200.192 114.4C166.783 114.4 137.846 133.6 123.772 161.58L152.18 183.66C158.957 163.36 177.883 148.3 200.192 148.3Z" fill="#E94235"/> </g>  <defs>  <clipPath id="clip0_1_67">  <rect width="752" height="400" fill="white"/> </clipPath> </defs> </svg>`
let applePayList = `<svg id="apple_pay_saved" viewBox="0 0 32 22" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M29.1343 0.783203H2.86575C2.75634 0.783203 2.64674 0.783203 2.53754 0.783839C2.44522 0.784495 2.35312 0.785517 2.26101 0.788024C2.06015 0.793443 1.85756 0.805263 1.6592 0.840822C1.45768 0.876998 1.27015 0.936005 1.0872 1.02891C0.907346 1.12014 0.742688 1.23947 0.599993 1.38186C0.457237 1.52425 0.337606 1.68821 0.246161 1.8678C0.152996 2.05028 0.0937985 2.23739 0.0577814 2.43855C0.0219401 2.63646 0.0100098 2.83849 0.00459659 3.03863C0.00212198 3.1305 0.0010606 3.22237 0.000459349 3.31421C-0.000178636 3.42338 3.40259e-05 3.53246 3.40259e-05 3.64182V18.3585C3.40259e-05 18.4679 -0.000178636 18.5768 0.000459349 18.6862C0.0010606 18.778 0.00212198 18.8699 0.00459659 18.9617C0.0100098 19.1617 0.0219401 19.3637 0.0577814 19.5616C0.0937985 19.7628 0.152996 19.9499 0.246161 20.1324C0.337606 20.3119 0.457237 20.4761 0.599993 20.6183C0.742688 20.7609 0.907346 20.8802 1.0872 20.9712C1.27015 21.0644 1.45768 21.1234 1.6592 21.1596C1.85756 21.1949 2.06015 21.2069 2.26101 21.2123C2.35312 21.2144 2.44522 21.2157 2.53754 21.2161C2.64674 21.2169 2.75634 21.2169 2.86575 21.2169H29.1343C29.2435 21.2169 29.3531 21.2169 29.4623 21.2161C29.5544 21.2157 29.6465 21.2144 29.739 21.2123C29.9395 21.2069 30.142 21.1949 30.3409 21.1596C30.5421 21.1234 30.7297 21.0644 30.9126 20.9712C31.0927 20.8802 31.2569 20.7609 31.3999 20.6183C31.5424 20.4761 31.662 20.3119 31.7537 20.1324C31.8471 19.9499 31.9062 19.7628 31.942 19.5616C31.9779 19.3637 31.9895 19.1617 31.995 18.9617C31.9975 18.8699 31.9987 18.778 31.9991 18.6862C32 18.5768 32 18.4679 32 18.3585V3.64182C32 3.53246 32 3.42338 31.9991 3.31421C31.9987 3.22237 31.9975 3.1305 31.995 3.03863C31.9895 2.83849 31.9779 2.63646 31.942 2.43855C31.9062 2.23739 31.8471 2.05028 31.7537 1.8678C31.662 1.68821 31.5424 1.52425 31.3999 1.38186C31.2569 1.23947 31.0927 1.12014 30.9126 1.02891C30.7297 0.936005 30.5421 0.876998 30.3409 0.840822C30.142 0.805263 29.9395 0.793443 29.739 0.788024C29.6465 0.785517 29.5544 0.784495 29.4623 0.783839C29.3531 0.783203 29.2435 0.783203 29.1343 0.783203Z" fill="black"/><path d="M29.1343 1.46387L29.4574 1.46448C29.545 1.4651 29.6325 1.46605 29.7205 1.46844C29.8737 1.47256 30.0528 1.48084 30.2197 1.51069C30.3649 1.53676 30.4866 1.57641 30.6034 1.63572C30.7187 1.69417 30.8244 1.77076 30.9166 1.86265C31.0092 1.95515 31.0861 2.06071 31.1455 2.17701C31.2046 2.29261 31.2441 2.41344 31.2701 2.55926C31.3 2.72398 31.3082 2.90313 31.3124 3.0568C31.3148 3.14353 31.3159 3.23027 31.3164 3.31907C31.3172 3.42646 31.3172 3.53379 31.3172 3.64139V18.3581C31.3172 18.4657 31.3172 18.5728 31.3163 18.6825C31.3159 18.7692 31.3148 18.856 31.3124 18.9429C31.3082 19.0963 31.3 19.2754 31.2697 19.442C31.2441 19.5858 31.2047 19.7067 31.1452 19.8229C31.086 19.9389 31.0092 20.0443 30.917 20.1362C30.8242 20.2288 30.7189 20.3052 30.6022 20.3642C30.4863 20.4232 30.3648 20.4628 30.2211 20.4886C30.0508 20.5189 29.8641 20.5272 29.7236 20.531C29.6352 20.533 29.5471 20.5342 29.457 20.5346C29.3496 20.5354 29.2417 20.5354 29.1343 20.5354H2.86576C2.86433 20.5354 2.86293 20.5354 2.86148 20.5354C2.75527 20.5354 2.64884 20.5354 2.54069 20.5346C2.45252 20.5342 2.36453 20.533 2.27947 20.5311C2.13571 20.5272 1.94897 20.5189 1.78002 20.4888C1.63509 20.4628 1.51358 20.4232 1.39611 20.3634C1.28052 20.3049 1.17529 20.2286 1.08247 20.1359C0.99037 20.0442 0.913831 19.9391 0.854653 19.8229C0.795417 19.7068 0.755785 19.5856 0.729726 19.4401C0.699604 19.2737 0.691329 19.0954 0.687194 18.943C0.684833 18.8558 0.683847 18.7685 0.683287 18.6818L0.682861 18.4257L0.682881 18.3581V3.64139L0.682861 3.57379L0.683267 3.31826C0.683847 3.231 0.684833 3.14376 0.687194 3.05658C0.691329 2.90403 0.699604 2.72562 0.729976 2.55789C0.755804 2.41367 0.795417 2.29246 0.854963 2.17581C0.913677 2.06052 0.990351 1.95527 1.08294 1.86294C1.17516 1.77092 1.28073 1.69442 1.39706 1.63541C1.51327 1.57639 1.63501 1.53676 1.77994 1.51075C1.94694 1.48082 2.12618 1.47256 2.27968 1.46842C2.36718 1.46605 2.45468 1.4651 2.54153 1.4645L2.86576 1.46387H29.1343Z" fill="white"/><path d="M8.73583 7.65557C9.00982 7.31374 9.19575 6.85476 9.14672 6.38574C8.74563 6.40564 8.25618 6.64968 7.97281 6.99178C7.71838 7.28473 7.49318 7.76292 7.55189 8.21228C8.00213 8.25124 8.45196 7.98781 8.73583 7.65557Z" fill="black"/><path d="M9.14155 8.30045C8.4877 8.26161 7.93176 8.6706 7.6195 8.6706C7.30708 8.6706 6.82892 8.32003 6.31175 8.32948C5.63863 8.33934 5.01404 8.71896 4.67246 9.32273C3.96988 10.5306 4.48705 12.3222 5.17027 13.3059C5.50206 13.7926 5.90192 14.3285 6.4288 14.3092C6.92661 14.2897 7.12173 13.9877 7.72684 13.9877C8.3315 13.9877 8.50726 14.3092 9.03423 14.2995C9.5807 14.2897 9.92234 13.8126 10.2541 13.3254C10.6347 12.7706 10.7906 12.2349 10.8004 12.2055C10.7906 12.1958 9.74661 11.7963 9.73693 10.5985C9.72707 9.5956 10.5565 9.11854 10.5956 9.08896C10.1272 8.39795 9.39529 8.32003 9.14155 8.30045Z" fill="black"/><path d="M14.8348 6.94238C16.256 6.94238 17.2456 7.91949 17.2456 9.34209C17.2456 10.7698 16.2356 11.752 14.7992 11.752H13.2257V14.2478H12.0889V6.94238H14.8348V6.94238ZM13.2257 10.8001H14.5302C15.52 10.8001 16.0833 10.2686 16.0833 9.34717C16.0833 8.42582 15.52 7.89928 14.5353 7.89928H13.2257V10.8001Z" fill="black"/><path d="M17.5426 12.7346C17.5426 11.803 18.2583 11.231 19.5273 11.1601L20.989 11.074V10.664C20.989 10.0716 20.588 9.71725 19.9181 9.71725C19.2835 9.71725 18.8876 10.0209 18.7913 10.4969H17.7558C17.8167 9.53493 18.6389 8.82617 19.9586 8.82617C21.2529 8.82617 22.0802 9.50964 22.0802 10.5779V14.2483H21.0295V13.3725H21.0042C20.6947 13.9648 20.0195 14.3394 19.3191 14.3394C18.2735 14.3394 17.5426 13.6914 17.5426 12.7346ZM20.989 12.2537V11.8335L19.6743 11.9144C19.0196 11.96 18.6491 12.2486 18.6491 12.7042C18.6491 13.1699 19.0348 13.4737 19.6236 13.4737C20.39 13.4737 20.989 12.9472 20.989 12.2537Z" fill="black"/><path d="M23.0722 16.2071V15.3211C23.1533 15.3413 23.336 15.3413 23.4274 15.3413C23.9349 15.3413 24.209 15.1287 24.3765 14.582C24.3765 14.5718 24.473 14.258 24.473 14.2529L22.5443 8.92188H23.7319L25.0821 13.2556H25.1023L26.4526 8.92188H27.6098L25.6098 14.5262C25.1532 15.8173 24.6253 16.2324 23.5188 16.2324C23.4274 16.2324 23.1533 16.2223 23.0722 16.2071Z" fill="black"/></svg>`
let samsungPay = `<svg xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" version="1.1" id="svg2" width="500.00534" height="141.69067" viewBox="0 0 500.00534 141.69067" sodipodi:docname="Samsung Pay_button_basic_pos_RGB.ai"> <defs id="defs6"> <clipPath clipPathUnits="userSpaceOnUse" id="clipPath16"> <path d="M 0,106.268 H 369.504 V 0 H 0 Z" id="path14"/> </clipPath> </defs> <sodipodi:namedview id="namedview4" pagecolor="#ffffff" bordercolor="#000000" borderopacity="0.25" inkscape:showpageshadow="2" inkscape:pageopacity="0.0" inkscape:pagecheckerboard="0" inkscape:deskcolor="#d1d1d1"/> <g id="g8" inkscape:groupmode="layer" inkscape:label="Samsung Pay_button_basic_pos_RGB" transform="matrix(1.3333333,0,0,-1.3333333,0,141.69067)"> <g id="g10"> <g id="g12" clip-path="url(#clipPath16)"> <g id="g18" transform="translate(9.0629,23.2361)"> <path d="m0 0v59.795c0 7.828 6.346 14.174 14.173 14.174h330.032c7.828 0 14.173-6.346 14.173-14.174V0c0-7.828-6.345-14.173-14.173-14.173H14.173C6.346-14.173 0-7.828 0 0" style="fill: #00000000;fill-opacity:1;fill-rule:nonzero;stroke:none" id="path20"/> </g> <g id="g22" transform="translate(250.1372,61.3994)"> <path d="m 0,0 v -9.745 h 3.768 c 2.898,0 4.926,2.174 4.926,4.891 C 8.694,-2.138 6.666,0 3.768,0 Z M -4.926,4.564 H 4.13 c 5.47,0 9.527,-4.202 9.527,-9.418 0,-5.253 -4.057,-9.455 -9.563,-9.455 H 0 v -7.571 h -4.926 z" style="fill:#ffffff;fill-opacity:1;fill-rule:nonzero;stroke:none" id="path24"/> </g> <g id="g26" transform="translate(282.6645,50.1699)"> <path d="m 0,0 c 0,3.622 -2.681,6.521 -6.339,6.521 -3.623,0 -6.412,-2.863 -6.412,-6.521 0,-3.695 2.789,-6.594 6.412,-6.594 C -2.681,-6.594 0,-3.659 0,0 m -17.568,-0.073 c 0,7.028 5.143,11.049 10.505,11.049 2.789,0 5.251,-1.123 6.809,-2.97 v 2.535 H 4.637 V -10.65 h -4.891 v 2.753 c -1.558,-1.993 -4.093,-3.188 -6.882,-3.188 -5.108,0 -10.432,4.057 -10.432,11.012" style="fill:#ffffff;fill-opacity:1;fill-rule:nonzero;stroke:none" id="path28"/> </g> <g id="g30" transform="translate(297.9477,40.5703)"> <path d="m 0,0 -8.693,20.141 h 5.215 L 2.428,5.868 8.006,20.141 h 5.143 L 0.508,-10.831 h -4.963 z" style="fill:#ffffff;fill-opacity:1;fill-rule:nonzero;stroke:none" id="path32"/> </g> <g id="g34" transform="translate(196.9545,66.9512)"> <path d="M 0,0 0.372,-21.534 H 0.221 L -6.083,0 h -10.183 v -27.15 h 6.747 l -0.379,22.277 h 0.151 l 6.772,-22.277 h 9.769 l 0,27.15 z" style="fill:#ffffff;fill-opacity:1;fill-rule:nonzero;stroke:none" id="path36"/> </g> <g id="g38" transform="translate(67.8142,66.9512)"> <path d="m 0,0 -5.086,-27.432 h 7.415 l 3.752,24.89 0.154,0.003 3.656,-24.893 h 7.37 L 12.205,0 Z" style="fill:#ffffff;fill-opacity:1;fill-rule:nonzero;stroke:none" id="path40"/> </g> <g id="g42" transform="translate(109.2656,66.9512)"> <path d="M 0,0 -3.384,-20.977 H -3.539 L -6.918,0 h -11.19 l -0.605,-27.432 h 6.867 l 0.171,24.66 h 0.152 l 4.582,-24.66 H 0.02 l 4.585,24.658 0.151,0.002 0.172,-24.66 H 11.79 L 11.185,0 Z" style="fill:#ffffff;fill-opacity:1;fill-rule:nonzero;stroke:none" id="path44"/> </g> <g id="g46" transform="translate(51.1826,47.2572)"> <path d="m 0,0 c 0.269,-0.664 0.183,-1.515 0.054,-2.029 -0.223,-0.914 -0.844,-1.847 -2.672,-1.847 -1.716,0 -2.757,0.994 -2.757,2.488 l -0.006,2.659 h -7.357 l -0.002,-2.115 c 0,-6.12 4.815,-7.968 9.97,-7.968 4.964,0 9.045,1.693 9.697,6.272 0.335,2.368 0.088,3.919 -0.029,4.497 -1.158,5.745 -11.566,7.458 -12.343,10.67 -0.13,0.557 -0.099,1.135 -0.029,1.442 0.194,0.881 0.79,1.842 2.506,1.842 1.607,0 2.548,-0.991 2.548,-2.485 v -1.7 h 6.846 v 1.932 c 0,5.975 -5.367,6.91 -9.25,6.91 -4.876,0 -8.864,-1.616 -9.591,-6.09 -0.199,-1.224 -0.226,-2.318 0.063,-3.7 C -11.162,5.171 -1.413,3.55 0,0" style="fill:#ffffff;fill-opacity:1;fill-rule:nonzero;stroke:none" id="path48"/> </g> <g id="g50" transform="translate(140.3747,47.3093)"> <path d="m 0,0 c 0.262,-0.659 0.181,-1.497 0.052,-2.009 -0.221,-0.903 -0.835,-1.824 -2.646,-1.824 -1.699,0 -2.731,0.98 -2.731,2.463 l -0.004,2.63 h -7.285 l -0.002,-2.095 c 0,-6.059 4.77,-7.887 9.874,-7.887 4.914,0 8.954,1.675 9.6,6.21 0.329,2.343 0.088,3.878 -0.03,4.453 C 5.679,7.63 -4.625,9.325 -5.39,12.505 c -0.134,0.549 -0.1,1.12 -0.034,1.424 0.194,0.872 0.785,1.824 2.481,1.824 1.595,0 2.525,-0.977 2.525,-2.46 v -1.68 h 6.779 v 1.91 c 0,5.916 -5.316,6.84 -9.16,6.84 -4.824,0 -8.774,-1.596 -9.492,-6.027 -0.198,-1.212 -0.225,-2.296 0.063,-3.662 C -11.054,5.119 -1.399,3.517 0,0" style="fill:#ffffff;fill-opacity:1;fill-rule:nonzero;stroke:none" id="path52"/> </g> <g id="g54" transform="translate(163.4048,43.6249)"> <path d="M 0,0 C 1.907,0 2.494,1.314 2.63,1.989 2.688,2.284 2.697,2.684 2.695,3.036 V 23.331 H 9.638 V 3.661 C 9.647,3.156 9.596,2.124 9.568,1.856 9.09,-3.264 5.043,-4.923 0,-4.923 c -5.045,0 -9.092,1.659 -9.573,6.779 -0.025,0.268 -0.077,1.3 -0.063,1.805 v 19.67 h 6.938 V 3.036 C -2.704,2.684 -2.691,2.284 -2.632,1.989 -2.499,1.314 -1.91,0 0,0" style="fill:#ffffff;fill-opacity:1;fill-rule:nonzero;stroke:none" id="path56"/> </g> <g id="g58" transform="translate(220.6237,43.9102)"> <path d="M 0,0 C 1.986,0 2.679,1.257 2.804,1.991 2.86,2.3 2.874,2.684 2.869,3.032 V 7.016 H 0.056 v 3.999 H 9.774 V 3.661 C 9.769,3.144 9.758,2.767 9.675,1.856 9.221,-3.142 4.889,-4.925 0.027,-4.925 c -4.864,0 -9.191,1.783 -9.65,6.781 -0.079,0.911 -0.092,1.288 -0.094,1.805 l 0.002,11.542 c 0,0.487 0.058,1.347 0.115,1.805 0.612,5.129 4.763,6.779 9.629,6.779 4.865,0 9.124,-1.634 9.63,-6.779 0.088,-0.873 0.058,-1.805 0.063,-1.805 V 14.288 H 2.804 v 1.538 c 0.002,-0.003 -0.005,0.65 -0.086,1.045 -0.124,0.605 -0.646,1.991 -2.743,1.991 -1.995,0 -2.582,-1.314 -2.733,-1.991 C -2.837,16.51 -2.869,16.02 -2.869,15.573 V 3.031 C -2.871,2.684 -2.858,2.3 -2.806,1.991 -2.677,1.257 -1.984,0 0,0" style="fill:#ffffff;fill-opacity:1;fill-rule:nonzero;stroke:none" id="path60"/> </g> <g id="g60" transform="translate(318.9477,40.5703)"> <path d="m19.888 13.312-11.872 11.872q-.304.304-.72.304t-.72-.304l-1.776-1.584q-.304-.304-.304-.72t.304-.72l9.28-9.28-9.28-9.6q-.304-.304-.304-.72t.304-.72L6.576 0q.304-.304.72-.304t.72.304l11.872 11.872q.304.304.304.72t-.304.72z" style="fill:#ffffff;fill-opacity:1;fill-rule:nonzero;stroke:none" id="path32"/> </g></g> </g> </g> </svg>`
let becsDebit = `<svg xmlns="http://www.w3.org/2000/svg" width="124" height="124" viewBox="0 0 20 21" fill="none"><path d="M9.99966 6.71422C10.3406 6.71422 10.6677 6.57876 10.9088 6.33765C11.1499 6.09653 11.2854 5.7695 11.2854 5.42851C11.2854 5.08751 11.1499 4.76049 10.9088 4.51937C10.6677 4.27825 10.3406 4.14279 9.99966 4.14279C9.65866 4.14279 9.33164 4.27825 9.09052 4.51937C8.8494 4.76049 8.71394 5.08751 8.71394 5.42851C8.71394 5.7695 8.8494 6.09653 9.09052 6.33765C9.33164 6.57876 9.65866 6.71422 9.99966 6.71422ZM10.7625 0.967079C10.5415 0.804186 10.2742 0.716309 9.99966 0.716309C9.72512 0.716309 9.45779 0.804186 9.2368 0.967079L1.09394 6.97136C0.0962268 7.70765 0.616513 9.29165 1.8568 9.29165H2.28537V15.4991C1.77757 15.7107 1.34379 16.0679 1.03871 16.5256C0.733627 16.9834 0.570915 17.5212 0.571084 18.0714V19.3571C0.571084 19.7119 0.859084 19.9999 1.21394 19.9999H18.7854C18.9559 19.9999 19.1194 19.9322 19.2399 19.8116C19.3605 19.6911 19.4282 19.5276 19.4282 19.3571V18.0714C19.4282 17.5214 19.2654 16.9837 18.9604 16.5261C18.6553 16.0685 18.2216 15.7115 17.7139 15.4999V9.29165H18.1417C19.3828 9.29165 19.9031 7.70765 18.9045 6.97136L10.7625 0.967079ZM3.57108 15.2857V9.29165H5.71394V15.2857H3.57108ZM16.4282 9.29165V15.2857H14.2854V9.29165H16.4282ZM12.9997 9.29165V15.2857H10.6425V9.29165H12.9997ZM9.3568 9.29165V15.2857H6.99966V9.29165H9.3568ZM1.8568 8.00594L9.99966 2.00165L18.1417 8.00594H1.8568ZM1.8568 18.0714C1.8568 17.2434 2.5288 16.5714 3.3568 16.5714H16.6425C17.4705 16.5714 18.1425 17.2434 18.1425 18.0714V18.7142H1.8568V18.0714Z" fill="black"/></svg>`
let cartesBancaires = `<svg class="PaymentLogo PaymentElementAccordionGraphicFormCardField__logo" width="34" height="24" viewBox="0 0 34 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M30 0H4C1.79086 0 0 1.79086 0 4v16c0 2.2091 1.79086 4 4 4h26c2.2091 0 4-1.7909 4-4V4c0-2.20914-1.7909-4-4-4Z" fill="url(#a-payment-logo-CartesBancaires-)"></path><path fill-rule="evenodd" clip-rule="evenodd" d="M10.817 6c4.0605 0 6.6394 2.21163 6.8078 5.6391h-6.5936v.7076h6.5946C17.4651 15.7736 14.9082 18 10.817 18 6.7321 18 4 15.7475 4 12c0-3.63257 2.6275-6 6.817-6Zm15.8831 6.3467c.6194 0 1.1092.0549 1.469.1647.3598.11.69.3034.9906.5803.2733.2505.4806.5384.6218.8635.1458.3429.2185.6923.2185 1.0483 0 .3561-.0727.7054-.2185 1.0483-.1412.3252-.3485.6131-.6218.8637-.3006.2768-.6308.4701-.9906.5801-.3598.1098-.8496.1648-1.469.1648h-8.325v-5.3137h8.325Zm0-6.00714c.6194 0 1.1092.05476 1.469.16429.3598.10958.69.30253.9906.57871.2733.24979.4806.53695.6218.86126.1458.34193.2185.69055.2185 1.04548 0 .3551-.0727.70355-.2185 1.0455-.1412.3244-.3485.6114-.6218.8613-.3006.2762-.6308.4691-.9906.5786-.3598.1096-.8496.1644-1.469.1644h-8.325V6.33956h8.325Z" fill="#FFFFFE"></path><defs><linearGradient id="a-payment-logo-CartesBancaires-" x1="4.9e-7" y1="17.9792" x2="28.3269" y2="-2.01619" gradientUnits="userSpaceOnUse"><stop stop-color="#00A26C"></stop><stop offset=".486821" stop-color="#007DB5"></stop><stop offset="1" stop-color="#003877"></stop></linearGradient></defs></svg>`

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
  ~fallbackIcon: option<string>=?,
) => {
  defaultView->ignore
  let (isLoaded, setIsLoaded) = React.useState(_ => false)
  let (iconName, setIconName) = React.useState(_ => name->String.toLowerCase)

  React.useEffect1(() => {
    setIconName(_ => name->String.toLowerCase)
    None
  }, [name])

  let getAssetUrl = GlobalHooks.useGetAssetUrlWithVersion()

  let uri = React.useMemo1(() => {
    let assetUrl = `${getAssetUrl()}/images/error.svg`

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
    | "defaulttick" => defaultTick
    | "google pay" => google_pay
    | "apple pay" => applePayList
    | "samsung_pay" => samsungPay
    | "becs debit"
    | "bacs debit" => becsDebit
    | "cartesbancaires" => cartesBancaires
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
            setIconName(_ => fallbackIcon->Option.getOr("error"))
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
            setIconName(_ => fallbackIcon->Option.getOr("error"))
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
