//
//  SampleData.swift
//  Chet
//
//  Created by gian singh on 9/1/25.
//

import Foundation

enum SampleData {
    static let searchedLine: LineObjFromSearch  = srchedLine
    static let shabadResponse: ShabadAPIResponse = sbdRes
    static let sbdHist: ShabadHistory = .init(sbdRes: sbdRes, indexOfSelectedLine: 1)
    static let fld: Folder = .init(name: "Test")
    static let svdSbd: SavedShabad = .init(folder:fld, sbdRes: sbdRes, indexOfSelectedLine: 1)
    static let emptySbd: ShabadAPIResponse = .init(
        shabadinfo: ShabadInfo(
            shabadid: "",
            pageno: 0,
            source: Source(
                id: 0,
                akhar: "",
                unicode: "",
                english: "",
                length: 0,
                pageName: PageName( akhar: "", unicode: "", english: "")
            ),
            writer: Writer( id: 0, akhar: "", unicode: "", english: ""),
            raag: Raag( id: 0, akhar: "", unicode: "", english: "", startang: 0, endang: 0, raagwithpage: ""),
            navigation: ShabadInfo.Navigation(
                previous: ShabadInfo.Navigation.NavigationItem(id: ""),
                next: ShabadInfo.Navigation.NavigationItem(id: "")
            ),
            count: 0
        ),
        shabad: [
            ShabadLineWrapper(
                line: LineOfShabad(
                    id: "",
                    type: 0,
                    gurmukhi: TextPair(akhar: "No Favorite Shabads", unicode: "No Favorite Shabads"),
                    larivaar: TextPair(akhar: "No Favorite Shabads", unicode: "No Favorite Shabads"),
                    translation: Translation(
                        english: .init(default: ""),
                        punjabi: .init(default: TextPair(akhar: "", unicode: "")),
                        spanish: ""
                    ),
                    transliteration: Transliteration(
                        english: .init(text: "", larivaar: ""),
                        devanagari: .init(text: "", larivaar: "")
                    ),
                    firstletters: TextPair(akhar: "", unicode: ""),
                    linenum: 2
                )
            ),
        ],
        error: false
    )
    static let emptyHukam: HukamnamaAPIResponse = .init(
        date: .init(
            gregorian: .init(
                month: "",
                monthno: 9,
                date: 1,
                year: 2025,
                day: ""
            )
        ),
        hukamnamainfo: .init(
            shabadid: [""],
            pageno: 671,
            source: .init(
                id: 1,
                akhar: "",
                unicode: "",
                english: "",
                length: 0,
                pageName: .init(
                    akhar: "",
                    unicode: "",
                    english: ""
                )
            ),
            writer: .init(
                id: 5,
                akhar: "",
                unicode: "",
                english: ""
            ),
            raag: .init(
                id: 14,
                akhar: "",
                unicode: "",
                english: "",
                startang: 660,
                endang: 695,
                raagwithpage: ""
            ),
            count: 0
        ),
        hukamnama: [
            .init(line: .init(
                id: "",
                type: 2,
                gurmukhi: .init(
                    akhar: "No Hukamnama",
                    unicode: "No Hukamnama"
                ),
                larivaar: .init(
                    akhar: "",
                    unicode: ""
                ),
                translation: .init(
                    english: .init(default: "No Hukamnama"),
                    punjabi: .init(default: .init(akhar: "", unicode: "")),
                    spanish: ""
                ),
                transliteration: .init(
                    english: .init(text: "", larivaar: ""),
                    devanagari: .init(text: "", larivaar: "")
                ),
                firstletters: .init(akhar: "", unicode: ""),
                linenum: 16
            )),
        ],
        error: false
    )
    static let hukamnamResponse: HukamnamaAPIResponse = .init(
        date: .init(
            gregorian: .init(
                month: "September",
                monthno: 9,
                date: 1,
                year: 2025,
                day: "Monday"
            )
        ),
        hukamnamainfo: .init(
            shabadid: ["QTM"],
            pageno: 671,
            source: .init(
                id: 1,
                akhar: "SRI gurU gRMQ swihb jI",
                unicode: "ਸ਼੍ਰੀ ਗੁਰੂ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ",
                english: "Sri Guru Granth Sahib Ji",
                length: 1430,
                pageName: .init(
                    akhar: "AMg",
                    unicode: "ਅੰਗ",
                    english: "Ang"
                )
            ),
            writer: .init(
                id: 5,
                akhar: "gurU Arjn dyv jI",
                unicode: "ਗੁਰੂ ਅਰਜਨ ਦੇਵ ਜੀ",
                english: "Guru Arjan Dev Ji"
            ),
            raag: .init(
                id: 14,
                akhar: "rwgu DnwsrI",
                unicode: "ਰਾਗੁ ਧਨਾਸਰੀ",
                english: "Raag Dhanaasree",
                startang: 660,
                endang: 695,
                raagwithpage: "Raag Dhanaasree (660-695)"
            ),
            count: 11
        ),
        hukamnama: [
            .init(line: .init(
                id: "H8T3",
                type: 2,
                gurmukhi: .init(
                    akhar: "DnwsrI mhlw 5 ]",
                    unicode: "ਧਨਾਸਰੀ ਮਹਲਾ ੫ ॥"
                ),
                larivaar: .init(
                    akhar: "DnwsrI​mhlw​5​]",
                    unicode: "ਧਨਾਸਰੀ​ਮਹਲਾ​੫​॥"
                ),
                translation: .init(
                    english: .init(default: "Dhanaasaree, Fifth Mahalaa:"),
                    punjabi: .init(default: .init(akhar: "", unicode: "")),
                    spanish: "Dhanasri, Mejl Guru Aryan, Quinto Canal Divino."
                ),
                transliteration: .init(
                    english: .init(text: "dhanaasaree mahalaa 5 |", larivaar: "dhanaasaree​mahalaa​5​|"),
                    devanagari: .init(text: "धनासरी महला ५ ॥", larivaar: "धनासरी​महला​५​॥")
                ),
                firstletters: .init(akhar: "Dm5]", unicode: "ਧਮ੫॥"),
                linenum: 16
            )),
            .init(line: .init(
                id: "VC5W",
                type: 4,
                gurmukhi: .init(
                    akhar: "ijs kw qnu mnu Dnu sBu iqs kw soeI suGVu sujwnI ]",
                    unicode: "ਜਿਸ ਕਾ ਤਨੁ ਮਨੁ ਧਨੁ ਸਭੁ ਤਿਸ ਕਾ ਸੋਈ ਸੁਘੜੁ ਸੁਜਾਨੀ ॥"
                ),
                larivaar: .init(
                    akhar: "ijs​kw​qnu​mnu​Dnu​sBu​iqs​kw​soeI​suGVu​sujwnI​]",
                    unicode: "ਜਿਸ​ਕਾ​ਤਨੁ​ਮਨੁ​ਧਨੁ​ਸਭੁ​ਤਿਸ​ਕਾ​ਸੋਈ​ਸੁਘੜੁ​ਸੁਜਾਨੀ​॥"
                ),
                translation: .init(
                    english: .init(default: "Body, mind, wealth and everything belong to Him; He alone is all-wise and all-knowing."),
                    punjabi: .init(default: .init(
                        akhar: "hy BweI! ijs pRBU dw id`qw hoieAw ieh srIr qy mn hY, ieh swrw Dn-pdwrQ BI ausy dw id`qw hoieAw hY, auhI suc`jw hY qy isAwxw hY[",
                        unicode: "ਹੇ ਭਾਈ! ਜਿਸ ਪ੍ਰਭੂ ਦਾ ਦਿੱਤਾ ਹੋਇਆ ਇਹ ਸਰੀਰ ਤੇ ਮਨ ਹੈ, ਇਹ ਸਾਰਾ ਧਨ-ਪਦਾਰਥ ਭੀ ਉਸੇ ਦਾ ਦਿੱਤਾ ਹੋਇਆ ਹੈ, ਉਹੀ ਸੁਚੱਜਾ ਹੈ ਤੇ ਸਿਆਣਾ ਹੈ।"
                    )),
                    spanish: "Solo es Todo Sabio, Aquél a quien pertenecen nuestro cuerpo, mente y riquezas."
                ),
                transliteration: .init(
                    english: .init(text: "jis kaa tan man dhan sabh tis kaa soee sugharr sujaanee |", larivaar: "jis​kaa​tan​man​dhan​sabh​tis​kaa​soee​sugharr​sujaanee​|"),
                    devanagari: .init(text: "जिस का तनु मनु धनु सभु तिस का सोई सुघड़ु सुजानी ॥", larivaar: "जिस​का​तनु​मनु​धनु​सभु​तिस​का​सोई​सुघड़ु​सુजानी​॥")
                ),
                firstletters: .init(akhar: "jkqmDsqksss", unicode: "ਜਕਤਮਧਸਤਕਸਸਸ"),
                linenum: 16
            )),
            .init(line: .init(
                id: "LGXW",
                type: 4,
                gurmukhi: .init(
                    akhar: "iqn hI suixAw duKu suKu myrw qau ibiD nIkI KtwnI ]1]",
                    unicode: "ਤਿਨ ਹੀ ਸੁਣਿਆ ਦੁਖੁ ਸੁਖੁ ਮੇਰਾ ਤਉ ਬਿਧਿ ਨੀਕੀ ਖਟਾਨੀ ॥੧॥"
                ),
                larivaar: .init(
                    akhar: "iqn​hI​suixAw​duKu​suKu​myrw​qau​ibiD​nIkI​KtwnI​]1]",
                    unicode: "ਤਿਨ​ਹੀ​ਸੁਣਿਆ​ਦੁਖੁ​ਸੁਖੁ​ਮੇਰਾ​ਤਉ​ਬਿਧਿ​ਨੀਕੀ​ਖਟਾਨੀ​॥੧॥"
                ),
                translation: .init(
                    english: .init(default: "He listens to my pains and pleasures, and then my condition improves. ||1||"),
                    punjabi: .init(default: .init(
                        akhar: "AsW jIvW dw du`K suK (sdw) aus prmwqmw ny hI suixAw hY, (jdoN auh swfI Ardws-ArzoeI suxdw hY) qdoN (swfI) hwlq cMgI bx jWdI hY ]1]",
                        unicode: "ਅਸਾਂ ਜੀਵਾਂ ਦਾ ਦੁੱਖ ਸੁਖ (ਸਦਾ) ਉਸ ਪਰਮਾਤਮਾ ਨੇ ਹੀ ਸੁਣਿਆ ਹੈ, (ਜਦੋਂ ਉਹ ਸਾਡੀ ਅਰਦਾਸ-ਅਰਜ਼ੋਈ ਸੁਣਦਾ ਹੈ) ਤਦੋਂ (ਸਾਡੀ) ਹਾਲਤ ਚੰਗੀ ਬਣ ਜਾਂਦੀ ਹੈ ॥੧॥"
                    )),
                    spanish: "Sólo ese Dios escucha y sabe de mis dichas y de mis tristezas. Es así como mi mente se vuelve íntegra. (1)"
                ),
                transliteration: .init(
                    english: .init(text: "tin hee suniaa dukh sukh meraa tau bidh neekee khattaanee |1|", larivaar: "tin​hee​suniaa​dukh​sukh​meraa​tau​bidh​neekee​khattaanee​|1|"),
                    devanagari: .init(text: "तिन ही सुणिआ दुखु सुखु मेरा तउ बिधि नीकी खटानी ॥१॥", larivaar: "तिन​ही​सुणिआ​दुखु​सुखु​मेरा​तउ​बिधि​नीकी​खटानी​॥१॥")
                ),
                firstletters: .init(akhar: "qhsdsmqbnK", unicode: "ਤਹਸਦਸਮਤਬਨਖ"),
                linenum: 17
            )),
            .init(line: .init(
                id: "YDYH",
                type: 3,
                gurmukhi: .init(
                    akhar: "jIA kI eykY hI pih mwnI ]",
                    unicode: "ਜੀਅ ਕੀ ਏਕੈ ਹੀ ਪਹਿ ਮਾਨੀ ॥"
                ),
                larivaar: .init(
                    akhar: "jIA​kI​eykY​hI​pih​mwnI​]",
                    unicode: "ਜੀਅ​ਕੀ​ਏਕੈ​ਹੀ​ਪਹਿ​ਮਾਨੀ​॥"
                ),
                translation: .init(
                    english: .init(default: "My soul is satisfied with the One Lord alone."),
                    punjabi: .init(default: .init(
                        akhar: "hy BweI! ijMd dI (Ardws) iek prmwqmw dy kol hI mMnI jWdI hY[",
                        unicode: "ਹੇ ਭਾਈ! ਜਿੰਦ ਦੀ (ਅਰਦਾਸ) ਇਕ ਪਰਮਾਤਮਾ ਦੇ ਕੋਲ ਹੀ ਮੰਨੀ ਜਾਂਦੀ ਹੈ।"
                    )),
                    spanish: "Mi mente está satisfecha con mi Único Señor."
                ),
                transliteration: .init(
                    english: .init(text: "jeea kee ekai hee peh maanee |", larivaar: "jeea​kee​ekai​hee​peh​maanee​|"),
                    devanagari: .init(text: "जीअ की एकै ही पहि मानी ॥", larivaar: "जीअ​की​एकै​ही​पहि​मानी​॥")
                ),
                firstletters: .init(akhar: "jkehpm", unicode: "ਜਕੲਹਪਮ"),
                linenum: 17
            )),
            .init(line: .init(
                id: "VWJR",
                type: 3,
                gurmukhi: .init(
                    akhar: "Avir jqn kir rhy bhuqyry iqn iqlu nhI kImiq jwnI ] rhwau ]",
                    unicode: "ਅਵਰਿ ਜਤਨ ਕਰਿ ਰਹੇ ਬਹੁਤੇਰੇ ਤਿਨ ਤਿਲੁ ਨਹੀ ਕੀਮਤਿ ਜਾਨੀ ॥ ਰਹਾਉ ॥"
                ),
                larivaar: .init(
                    akhar: "Avir​jqn​kir​rhy​bhuqyry​iqn​iqlu​nhI​kImiq​jwnI​]​rhwau​]",
                    unicode: "ਅਵਰਿ​ਜਤਨ​ਕਰਿ​ਰਹੇ​ਬਹੁਤੇਰੇ​ਤਿਨ​ਤਿਲੁ​ਨਹੀ​ਕੀਮਤਿ​ਜਾਨੀ​॥​ਰਹਾਉ​॥"
                ),
                translation: .init(
                    english: .init(default: "People make all sorts of other efforts, but they have no value at all. ||Pause||"),
                    punjabi: .init(default: .init(
                        akhar: "(prmwqmw dy Awsry qoN ibnw lok) hor bQyry jqn kr ky Q`k jWdy hn, auhnW jqnW dw mu`l iek iql ijqnw BI nhIN smiJAw jWdw rhwau]",
                        unicode: "(ਪਰਮਾਤਮਾ ਦੇ ਆਸਰੇ ਤੋਂ ਬਿਨਾ ਲੋਕ) ਹੋਰ ਬਥੇਰੇ ਜਤਨ ਕਰ ਕੇ ਥੱਕ ਜਾਂਦੇ ਹਨ, ਉਹਨਾਂ ਜਤਨਾਂ ਦਾ ਮੁੱਲ ਇਕ ਤਿਲ ਜਿਤਨਾ ਭੀ ਨਹੀਂ ਸਮਝਿਆ ਜਾਂਦਾ ਰਹਾਉ॥"
                    )),
                    spanish: "He hecho muchos otros esfuerzos, pero mi mente no les da ningún valor. (Pausa)"
                ),
                transliteration: .init(
                    english: .init(text: "avar jatan kar rahe bahutere tin til nahee keemat jaanee | rahaau |", larivaar: "avar​jatan​kar​rahe​bahutere​tin​til​nahee​keemat​jaanee​|​rahaau​|"),
                    devanagari: .init(text: "अवरि जतन करि रहे बहुतेरे तिन तिलु नही कीमति जानी ॥ रहाउ ॥", larivaar: "अवरि​जतन​करि​रहे​बहुतेरे​तिन​तिलु​नही​कीमति​जानी​॥​रहाउ​॥")
                ),
                firstletters: .init(akhar: "Ajkrbqqnkj", unicode: "ਅਜਕਰਬਤਤਨਕਜ"),
                linenum: 17
            )),
            .init(line: .init(
                id: "2DSL",
                type: 4,
                gurmukhi: .init(
                    akhar: "AMimRq nwmu inrmolku hIrw guir dIno mMqwnI ]",
                    unicode: "ਅੰਮ੍ਰਿਤ ਨਾਮੁ ਨਿਰਮੋਲਕੁ ਹੀਰਾ ਗੁਰਿ ਦੀਨੋ ਮੰਤਾਨੀ ॥"
                ),
                larivaar: .init(
                    akhar: "AMimRq​nwmu​inrmolku​hIrw​guir​dIno​mMqwnI​]",
                    unicode: "ਅੰਮ੍ਰਿਤ​ਨਾਮੁ​ਨਿਰਮੋਲਕੁ​ਹੀਰਾ​ਗੁਰਿ​ਦੀਨੋ​ਮੰਤਾਨੀ​॥"
                ),
                translation: .init(
                    english: .init(default: "The Ambrosial Naam, the Name of the Lord, is a priceless jewel. The Guru has given me this advice."),
                    punjabi: .init(default: .init(
                        akhar: "hy BweI! prmwqmw dw nwm Awqmk jIvn dyx vwlw hY, nwm iek AYsw hIrw hY jyhVw iksy mu`l qoN nhIN iml skdw[ gurU ny ieh nwm-mMqr (ijs mnu`K ƒ) dy id`qw,",
                        unicode: "ਹੇ ਭਾਈ! ਪਰਮਾਤਮਾ ਦਾ ਨਾਮ ਆਤਮਕ ਜੀਵਨ ਦੇਣ ਵਾਲਾ ਹੈ, ਨਾਮ ਇਕ ਐਸਾ ਹੀਰਾ ਹੈ ਜੇਹੜਾ ਕਿਸੇ ਮੁੱਲ ਤੋਂ ਨਹੀਂ ਮਿਲ ਸਕਦਾ। ਗੁਰੂ ਨੇ ਇਹ ਨਾਮ-ਮੰਤਰ (ਜਿਸ ਮਨੁੱਖ ਨੂੰ) ਦੇ ਦਿੱਤਾ,"
                    )),
                    spanish: "El Naam Ambrosial, el Nombre del Señor, es la Joya Preciosa, esto lo aprendí del Guru."
                ),
                transliteration: .init(
                    english: .init(text: "amrit naam niramolak heeraa gur deeno mantaanee |", larivaar: "amrit​naam​niramolak​heeraa​gur​deeno​mantaanee​|"),
                    devanagari: .init(text: "अंम्रित नामु निरमोलकु हीरा गुरि दीनो मंतानी ॥", larivaar: "अंम्रित​नामु​निरमोलकु​हीरा​गुरि​दीनो​मंतानी​॥")
                ),
                firstletters: .init(akhar: "Annhgdm", unicode: "ਅਨਨਹਗਦਮ"),
                linenum: 18
            )),
            .init(line: .init(
                id: "JJSM",
                type: 4,
                gurmukhi: .init(
                    akhar: "ifgY n folY idRVu kir rihE pUrn hoie iqRpqwnI ]2]",
                    unicode: "ਡਿਗੈ ਨ ਡੋਲੈ ਦ੍ਰਿੜੁ ਕਰਿ ਰਹਿਓ ਪੂਰਨ ਹੋਇ ਤ੍ਰਿਪਤਾਨੀ ॥੨॥"
                ),
                larivaar: .init(
                    akhar: "ifgY​n​folY​idRVu​kir​rihE​pUrn​hoie​iqRpqwnI​]2]",
                    unicode: "ਡਿਗੈ​ਨ​ਡੋਲੈ​ਦ੍ਰਿੜੁ​ਕਰਿ​ਰਹਿਓ​ਪੂਰਨ​ਹੋਇ​ਤ੍ਰਿਪਤਾਨੀ​॥੨॥"
                ),
                translation: .init(
                    english: .init(default: "It cannot be lost, and it cannot be shaken off; it remains steady, and I am perfectly satisfied with it. ||2||"),
                    punjabi: .init(default: .init(
                        akhar: "auh mnu`K (ivkwrW ivc) if`gdw nhIN, foldw nhIN, auh mnu`K p`ky ierwdy vwlw bx jWdw hY, auh mukMml qOr qy (mwieAw vloN) sMqoKI rihMdw hY ]2]",
                        unicode: "ਉਹ ਮਨੁੱਖ (ਵਿਕਾਰਾਂ ਵਿਚ) ਡਿੱਗਦਾ ਨਹੀਂ, ਡੋਲਦਾ ਨਹੀਂ, ਉਹ ਮਨੁੱਖ ਪੱਕੇ ਇਰਾਦੇ ਵਾਲਾ ਬਣ ਜਾਂਦਾ ਹੈ, ਉਹ ਮੁਕੰਮਲ ਤੌਰ ਤੇ (ਮਾਇਆ ਵਲੋਂ) ਸੰਤੋਖੀ ਰਹਿੰਦਾ ਹੈ ॥੨॥"
                    )),
                    spanish: "No se puede perder y ser alterado, “permanece constante”, este Mantra está profundamente engarzado en mi mente y me provee de total satisfacción. (2)"
                ),
                transliteration: .init(
                    english: .init(text: "ddigai na ddolai drirr kar rahio pooran hoe tripataanee |2|", larivaar: "ddigai​na​ddolai​drirr​kar​rahio​pooran​hoe​tripataanee​|2|"),
                    devanagari: .init(text: "डिगै न डोलै द्रिड़ु करि रहिओ पूरन होइ त्रिपतानी ॥२॥", larivaar: "डिगै​न​डोलै​द्रिड़ु​करि​रहिओ​पूरन​होइ​त्रिपतानी​॥२॥")
                ),
                firstletters: .init(akhar: "fnfdkrphq", unicode: "ਡਨਡਦਕਰਪਹਤ"),
                linenum: 19
            )),
            .init(line: .init(
                id: "5JC2",
                type: 4,
                gurmukhi: .init(
                    akhar: "Eie ju bIc hm qum kCu hoqy iqn kI bwq iblwnI ]",
                    unicode: "ਓਇ ਜੁ ਬੀਚ ਹਮ ਤੁਮ ਕਛੁ ਹੋਤੇ ਤਿਨ ਕੀ ਬਾਤ ਬਿਲਾਨੀ ॥"
                ),
                larivaar: .init(
                    akhar: "Eie​ju​bIc​hm​qum​kCu​hoqy​iqn​kI​bwq​iblwnI​]",
                    unicode: "ਓਇ​ਜੁ​ਬੀਚ​ਹਮ​ਤੁਮ​ਕਛੁ​ਹੋਤੇ​ਤਿਨ​ਕੀ​ਬਾਤ​ਬਿਲਾਨੀ​॥"
                ),
                translation: .init(
                    english: .init(default: "Those things which tore me away from You, Lord, are now gone."),
                    punjabi: .init(default: .init(
                        akhar: "(hy BweI! ijs mnu`K ƒ gurU pwsoN nwm-hIrw iml ਜWdw hY, aus dy AMdroN) auhnW myr-qyr vwly swry ivqkirAW dI g`l mu`k jWdI hY jo jgq ivc bVy pRbl hn[",
                        unicode: "(ਹੇ ਭਾਈ! ਜਿਸ ਮਨੁੱਖ ਨੂੰ ਗੁਰੂ ਪਾਸੋਂ ਨਾਮ-ਹੀਰਾ ਮਿਲ ਜਾਂਦਾ ਹੈ, ਉਸ ਦੇ ਅੰਦਰੋਂ) ਉਹਨਾਂ ਮੇਰ-ਤੇਰ ਵਾਲੇ ਸਾਰੇ ਵਿਤਕਰਿਆਂ ਦੀ ਗੱਲ ਮੁੱਕ ਜਾਂਦੀ ਹੈ ਜੋ ਜਗਤ ਵਿਚ ਬੜੇ ਪ੍ਰਬਲ ਹਨ।"
                    )),
                    spanish: "Eso que me alejó de Ti y me destrozó, oh mi Señor, ahora se ha ido."
                ),
                transliteration: .init(
                    english: .init(text: "oe ju beech ham tum kachh hote tin kee baat bilaanee |", larivaar: "oe​ju​beech​ham​tum​kachh​hote​tin​kee​baat​bilaanee​|"),
                    devanagari: .init(text: "ओइ जु बीच हम तुम कछु होते तिन की बात बिलानी ॥", larivaar: "ओइ​जु​बीच​हम​तुम​कछु​होते​तिन​की​बात​बिलानी​॥")
                ),
                firstletters: .init(akhar: "ajbhqkhqkbb", unicode: "ੳਜਬਹਤਕਹਤਕਬਬ"),
                linenum: 19
            )),
            .init(line: .init(
                id: "EB06",
                type: 4,
                gurmukhi: .init(
                    akhar: "Alµkwr imil QYlI hoeI hY qw qy kink vKwnI ]3]",
                    unicode: "ਅਲੰਕਾਰ ਮਿਲਿ ਥੈਲੀ ਹੋਈ ਹੈ ਤਾ ਤੇ ਕਨਿਕ ਵਖਾਨੀ ॥੩॥"
                ),
                larivaar: .init(
                    akhar: "Alµkwr​imil​QYlI​hoeI​hY​qw​qy​kink​vKwnI​]3]",
                    unicode: "ਅਲੰਕਾਰ​ਮਿਲਿ​ਥੈਲੀ​ਹੋਈ​ਹੈ​ਤਾ​ਤੇ​ਕਨਿਕ​ਵਖਾਨੀ​॥੩॥"
                ),
                translation: .init(
                    english: .init(default: "When golden ornaments are melted down into a lump, they are still said to be gold. ||3||"),
                    punjabi: .init(default: .init(
                        akhar: "(aus mnu`K ƒ hr pwsy prmwqmw hI ieauN id`sdw hY, ijvyN) AnykW ghxy iml ky (gwly jw ky) rYxI bx jWdI hY, qy, aus FylI qoN auh sonw hI AKvWdI hY ]3]",
                        unicode: "(ਉਸ ਮਨੁੱਖ ਨੂੰ ਹਰ ਪਾਸੇ ਪਰਮਾਤਮਾ ਹੀ ਇਉਂ ਦਿੱਸਦਾ ਹੈ, ਜਿਵੇਂ) ਅਨੇਕਾਂ ਗਹਣੇ ਮਿਲ ਕੇ (ਗਾਲੇ ਜਾ ਕੇ) ਰੈਣੀ ਬਣ ਜਾਂਦੀ ਹੈ, ਤੇ, ਉਸ ਢੇਲੀ ਤੋਂ ਉਹ ਸੋਨਾ ਹੀ ਅਖਵਾਂਦੀ ਹੈ ॥੩॥"
                    )),
                    spanish: "Así como los ornamentos dorados fueron echados al fuego y fundidos, y siguen siendo oro. (3)"
                ),
                transliteration: .init(
                    english: .init(text: "alankaar mil thailee hoee hai taa te kanik vakhaanee |3|", larivaar: "alankaar​mil​thailee​hoee​hai​taa​te​kanik​vakhaanee​|3|"),
                    devanagari: .init(text: "अलंकार मिलि थैली होई है ता ते कनिक वखानी ॥३॥", larivaar: "अलंकार​मिलि​थैली​होई​है​ता​ते​कनिक​वखानी​॥३॥")
                ),
                firstletters: .init(akhar: "AmQhhqqkv", unicode: "ਅਮਥਹਹਤਤਕਵ"),
                linenum: 1
            )),
            .init(line: .init(
                id: "75MQ",
                type: 4,
                gurmukhi: .init(
                    akhar: "pRgitE joiq shj suK soBw bwjy Anhq bwnI ]",
                    unicode: "ਪ੍ਰਗਟਿਓ ਜੋਤਿ ਸਹਜ ਸੁਖ ਸੋਭਾ ਬਾਜੇ ਅਨਹਤ ਬਾਨੀ ॥"
                ),
                larivaar: .init(
                    akhar: "pRgitE​joiq​shj​suK​soBw​bwjy​Anhq​bwnI​]",
                    unicode: "ਪ੍ਰਗਟਿਓ​ਜੋਤਿ​ਸਹਜ​ਸੁਖ​ਸੋਭਾ​ਬਾਜੇ​ਅਨਹਤ​ਬਾਨੀ​॥"
                ),
                translation: .init(
                    english: .init(default: "The Divine Light has illuminated me, and I am filled with celestial peace and glory; the unstruck melody of the Lord's Bani resounds within me."),
                    punjabi: .init(default: .init(
                        akhar: "(hy BweI! ijs mnu`K dy AMdr gurU dI ikrpw nwl) prmwqmw dI joiq dw prkwS ho jWdw hY, aus dy AMdr Awqmk Afolqw dy Awnµd pYdw ho jWdy hn, aus ƒ hr QW soBw imldI hY, aus dy ihrdy ivc is&q-swlwh dI bwxI dy (mwno) iek-rs vwjy v`jdy rihMdy hn[",
                        unicode: "ਹੇ ਭਾਈ! ਜਿਸ ਮਨੁੱਖ ਦੇ ਅੰਦਰ ਗੁਰੂ ਦੀ ਕਿਰਪਾ ਨਾਲ) ਪਰਮਾਤਮਾ ਦੀ ਜੋਤਿ ਦਾ ਪਰਕਾਸ਼ ਹੋ ਜਾਂਦਾ ਹੈ, ਉਸ ਦੇ ਅੰਦਰ ਆਤਮਕ ਅਡੋਲਤਾ ਦੇ ਆਨੰਦ ਪੈਦਾ ਹੋ ਜਾਂਦੇ ਹਨ, ਉਸ ਨੂੰ ਹਰ ਥਾਂ ਸੋਭਾ ਮਿਲਦੀ ਹੈ, ਉਸ ਦੇ ਹਿਰਦੇ ਵਿਚ ਸਿਫ਼ਤ-ਸਾਲਾਹ ਦੀ ਬਾਣੀ ਦੇ (ਮਾਨੋ) ਇਕ-ਰਸ ਵਾਜੇ ਵੱਜਦੇ ਰਹਿੰਦੇ ਹਨ।"
                    )),
                    spanish: "Mi mente está iluminada con la Divina Luz de Dios, y está llena de Gloria, de Paz y de la Alabanza a Dios y en mi interior resuena la Melodía Celestial del Bani del Señor."
                ),
                transliteration: .init(
                    english: .init(text: "pragattio jot sehaj sukh sobhaa baaje anahat baanee |", larivaar: "pragattio​jot​sehaj​sukh​sobhaa​baaje​anahat​baanee​|"),
                    devanagari: .init(text: "प्रगटिओ जोति सहज सुख सोभा बाजे अनहत बानी ॥", larivaar: "प्रगटिओ​जोति​सहज​सुख​सोभा​बाजे​अनहत​बानी​॥")
                ),
                firstletters: .init(akhar: "pjsssbAb", unicode: "ਪਜਸਸਸਬਅਬ"),
                linenum: 1
            )),
            .init(line: .init(
                id: "JZJC",
                type: 4,
                gurmukhi: .init(
                    akhar: "khu nwnk inhcl Gru bwiDE guir kIE bMDwnI ]4]5]",
                    unicode: "ਕਹੁ ਨਾਨਕ ਨਿਹਚਲ ਘਰੁ ਬਾਧਿਓ ਗੁਰਿ ਕੀਓ ਬੰਧਾਨੀ ॥੪॥੫॥"
                ),
                larivaar: .init(
                    akhar: "khu​nwnk​inhcl​Gru​bwiDE​guir​kIE​bMDwnI​]4]5]",
                    unicode: "ਕਹੁ​ਨਾਨਕ​ਨਿਹਚਲ​ਘਰੁ​ਬਾਧਿਓ​ਗੁਰਿ​ਕੀਓ​ਬੰਧਾਨੀ​॥੪॥੫॥"
                ),
                translation: .init(
                    english: .init(default: "Says Nanak, I have built my eternal home; the Guru has constructed it for me. ||4||5||"),
                    punjabi: .init(default: .init(
                        akhar: "nwnk AwKdw hY- gurU ny ijs mnu`K vwsqy ieh pRbMD kr id`qw, auh mnu`K sdw leI pRBU-crnW ivc itkwxw pRwpq kr lYNdw hY ]4]5]",
                        unicode: "ਨਾਨਕ ਆਖਦਾ ਹੈ- ਗੁਰੂ ਨੇ ਜਿਸ ਮਨੁੱਖ ਵਾਸਤੇ ਇਹ ਪ੍ਰਬੰਧ ਕਰ ਦਿੱਤਾ, ਉਹ ਮਨੁੱਖ ਸਦਾ ਲਈ ਪ੍ਰਭੂ-ਚਰਨਾਂ ਵਿਚ ਟਿਕਾਣਾ ਪ੍ਰਾਪਤ ਕਰ ਲੈਂਦਾ ਹੈ ॥੪॥੫॥"
                    )),
                    spanish: "Dice Nanak, he construido mi Hogar Eterno, el Guru lo construyó para mí. (4-5)"
                ),
                transliteration: .init(
                    english: .init(text: "kahu naanak nihachal ghar baadhio gur keeo bandhaanee |4|5|", larivaar: "kahu​naanak​nihachal​ghar​baadhio​gur​keeo​bandhaanee​|4|5|"),
                    devanagari: .init(text: "कहु नानक निहचल घरु बाधिओ गुरि कीओ बंधानी ॥४॥५॥", larivaar: "कहु​नानक​निहचल​घरु​बाधिओ​गुरि​कीओ​बंधानी​॥४॥५॥")
                ),
                firstletters: .init(akhar: "knnGbgkb", unicode: "ਕਨਨਘਬਗਕਬ"),
                linenum: 2
            )),
        ],
        error: false
    )
}

private let srchedLine: LineObjFromSearch = .init(
         id: "2GYN",
         shabadid: "4Z1",
         type: 4,
         gurmukhi: .init(
             akhar: "qyrw kIAw mITw lwgY ]",
             unicode: "ਤੇਰਾ ਕੀਆ ਮੀਠਾ ਲਾਗੈ ॥"
         ),
         larivaar: .init(
             akhar: "qyrw​kIAw​mITw​lwgY​]",
             unicode: "ਤੇਰਾ​ਕੀਆ​ਮੀਠਾ​ਲਾਗੈ​॥"
         ),
         translation: .init(
             english: .init(default: "Your actions seem so sweet to me."),
             punjabi: .init(default: .init(
                 akhar: "(hy pRBU! ieh qyry imlwey hoey gurU dI myhr hY ik) mYƒ qyrw kIqw hoieAw hryk kMm cMgw l`g irhw hY,",
                 unicode: "(ਹੇ ਪ੍ਰਭੂ! ਇਹ ਤੇਰੇ ਮਿਲਾਏ ਹੋਏ ਗੁਰੂ ਦੀ ਮੇਹਰ ਹੈ ਕਿ) ਮੈਨੂੰ ਤੇਰਾ ਕੀਤਾ ਹੋਇਆ ਹਰੇਕ ਕੰਮ ਚੰਗਾ ਲੱਗ ਰਿਹਾ ਹੈ,"
             )),
             spanish: "Dulces son para mí Tus acciones,"
         ),
         transliteration: .init(
             english: .init(text: "teraa keea meetthaa laagai |", larivaar: "teraa​keea​meetthaa​laagai​|"),
             devanagari: .init(text: "तेरा कीआ मीठा लागै ॥", larivaar: "तेरा​कीआ​मीठा​लागै​॥")
         ),
         firstletters: .init(
             akhar: "qkml",
             unicode: "ਤਕਮਲ"
         ),
         source: .init(
             id: 1,
             akhar: "SRI gurU gRMQ swihb jI",
             unicode: "ਸ਼੍ਰੀ ਗੁਰੂ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ",
             english: "Sri Guru Granth Sahib Ji",
             length: 1430,
             pageName: .init(akhar: "AMg", unicode: "ਅੰਗ", english: "Ang")
         ),
         writer: .init(
             id: 5,
             akhar: "gurU Arjn dyv jI",
             unicode: "ਗੁਰੂ ਅਰਜਨ ਦੇਵ ਜੀ",
             english: "Guru Arjan Dev Ji"
         ),
         raag: .init(
             id: 8,
             akhar: "rwgu Awsw",
             unicode: "ਰਾਗੁ ਆਸਾ",
             english: "Raag Aasaa",
             startang: 347,
             endang: 488,
             raagwithpage: "Raag Aasaa (347-488)"
         ),
         pageno: 394,
         lineno: 4
     )

private let sbdRes: ShabadAPIResponse = .init(
    shabadinfo: ShabadInfo(
        shabadid: "4Z1",
        pageno: 394,
        source: Source(
            id: 1,
            akhar: "SRI gurU gRMQ swihb jI",
            unicode: "ਸ਼੍ਰੀ ਗੁਰੂ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ",
            english: "Sri Guru Granth Sahib Ji",
            length: 1430,
            pageName: PageName(
                akhar: "AMg",
                unicode: "ਅੰਗ",
                english: "Ang"
            )
        ),
        writer: Writer(
            id: 5,
            akhar: "gurU Arjn dyv jI",
            unicode: "ਗੁਰੂ ਅਰਜਨ ਦੇਵ ਜੀ",
            english: "Guru Arjan Dev Ji"
        ),
        raag: Raag(
            id: 8,
            akhar: "rwgu Awsw",
            unicode: "ਰਾਗੁ ਆਸਾ",
            english: "Raag Aasaa",
            startang: 347,
            endang: 488,
            raagwithpage: "Raag Aasaa (347-488)"
        ),
        navigation: ShabadInfo.Navigation(
            previous: ShabadInfo.Navigation.NavigationItem(id: "K8R"),
            next: ShabadInfo.Navigation.NavigationItem(id: "BDU")
        ),
        count: 7
    ),
    shabad: [
        ShabadLineWrapper(
            line: LineOfShabad(
                id: "ZSLW",
                type: 2,
                gurmukhi: TextPair(akhar: "Awsw Gru 7 mhlw 5 ]", unicode: "ਆਸਾ ਘਰੁ ੭ ਮਹਲਾ ੫ ॥"),
                larivaar: TextPair(akhar: "Awsw​Gru​7​mhlw​5​]", unicode: "ਆਸਾ​ਘਰੁ​੭​ਮਹਲਾ​੫​॥"),
                translation: Translation(
                    english: .init(default: "Aasaa, Seventh House, Fifth Mahalaa:"),
                    punjabi: .init(default: TextPair(akhar: "", unicode: "")),
                    spanish: "Asa, Mejl Guru Aryan, Quinto Canal Divino."
                ),
                transliteration: Transliteration(
                    english: .init(text: "aasaa ghar 7 mahalaa 5 |", larivaar: "aasaa​ghar​7​mahalaa​5​|"),
                    devanagari: .init(text: "आसा घरु ७ महला ५ ॥", larivaar: "आसा​घरु​७​महला​५​॥")
                ),
                firstletters: TextPair(akhar: "AG7m5]", unicode: "ਅਘ੭ਮ੫॥"),
                linenum: 2
            )
        ),
        ShabadLineWrapper(
            line: LineOfShabad(
                id: "L7HP",
                type: 4,
                gurmukhi: TextPair(akhar: "hir kw nwmu irdY inq iDAweI ]", unicode: "ਹਰਿ ਕਾ ਨਾਮੁ ਰਿਦੈ ਨਿਤ ਧਿਆਈ ॥"),
                larivaar: TextPair(akhar: "hir​kw​nwmu​irdY​inq​iDAweI​]", unicode: "ਹਰਿ​ਕਾ​ਨਾਮੁ​ਰਿਦੈ​ਨਿਤ​ਧਿਆਈ​॥"),
                translation: Translation(
                    english: .init(default: "Meditate continually on the Name of the Lord within your heart."),
                    punjabi: .init(default: TextPair(
                        akhar: "(hy BweI! AMg-sMg v`sdy gurU dI hI ikrpw nwl) mYN prmwqmw dw nwm sdw Awpxy ihrdy ivc iDAwauNdw hW[",
                        unicode: "(ਹੇ ਭਾਈ! ਅੰਗ-ਸੰਗ ਵੱਸਦੇ ਗੁਰੂ ਦੀ ਹੀ ਕਿਰਪਾ ਨਾਲ) ਮੈਂ ਪਰਮਾਤਮਾ ਦਾ ਨਾਮ ਸਦਾ ਆਪਣੇ ਹਿਰਦੇ ਵਿਚ ਧਿਆਉਂਦਾ ਹਾਂ।"
                    )),
                    spanish: "Contempla siempre el Nombre de tu Señor"
                ),
                transliteration: Transliteration(
                    english: .init(text: "har kaa naam ridai nit dhiaaee |", larivaar: "har​kaa​naam​ridai​nit​dhiaaee​|"),
                    devanagari: .init(text: "हरि का नामु रिदै नित धिआई ॥", larivaar: "हरि​का​नामु​रिदै​नित​धिआई​॥")
                ),
                firstletters: TextPair(akhar: "hknrnD", unicode: "ਹਕਨਰਨਧ"),
                linenum: 2
            )
        ),
        ShabadLineWrapper(
            line: LineOfShabad(
                id: "B5BZ",
                type: 4,
                gurmukhi: TextPair(akhar: "sMgI swQI sgl qrWeI ]1]", unicode: "ਸੰਗੀ ਸਾਥੀ ਸਗਲ ਤਰਾਂਈ ॥੧॥"),
                larivaar: TextPair(akhar: "sMgI​swQI​sgl​qrWeI​]1]", unicode: "ਸੰਗੀ​ਸਾਥੀ​ਸਗਲ​ਤਰਾਂਈ​॥੧॥"),
                translation: Translation(
                    english: .init(default: "Thus you shall save all your companions and associates. ||1||"),
                    punjabi: .init(default: TextPair(
                        akhar: "(ies qrHW mYN sMswr-smuMdr qoN pwr lµGx jogw ho irhw hW) Awpxy sMgIAW swQIAW (igAwn-ieMidRAW) ƒ pwr lµGwx jogw bx irhw hW ]1]",
                        unicode: "(ਇਸ ਤਰ੍ਹਾਂ ਮੈਂ ਸੰਸਾਰ-ਸਮੁੰਦਰ ਤੋਂ ਪਾਰ ਲੰਘਣ ਜੋਗਾ ਹੋ ਰਿਹਾ ਹਾਂ) ਆਪਣੇ ਸੰਗੀਆਂ ਸਾਥੀਆਂ (ਗਿਆਨ-ਇੰਦ੍ਰਿਆਂ) ਨੂੰ ਪਾਰ ਲੰਘਾਣ ਜੋਗਾ ਬਣ ਰਿਹਾ ਹਾਂ ॥੧॥"
                    )),
                    spanish: "y así salvarás a todos tus asociados y compañeros. (1)"
                ),
                transliteration: Transliteration(
                    english: .init(text: "sangee saathee sagal taraanee |1|", larivaar: "sangee​saathee​sagal​taraanee​|1|"),
                    devanagari: .init(text: "संगी साथी सगल तरांई ॥१॥", larivaar: "संगी​साथी​सगल​तरांई​॥१॥")
                ),
                firstletters: TextPair(akhar: "sssq", unicode: "ਸਸਸਤ"),
                linenum: 2
            )
        ),
        ShabadLineWrapper(
            line: LineOfShabad(
                id: "EHEH",
                type: 3,
                gurmukhi: TextPair(akhar: "guru myrY sMig sdw hY nwly ]", unicode: "ਗੁਰੁ ਮੇਰੈ ਸੰਗਿ ਸਦਾ ਹੈ ਨਾਲੇ ॥"),
                larivaar: TextPair(akhar: "guru​myrY​sMig​sdw​hY​nwly​]", unicode: "ਗੁਰੁ​ਮੇਰੈ​ਸੰਗਿ​ਸਦਾ​ਹੈ​ਨਾਲੇ​॥"),
                translation: Translation(
                    english: .init(default: "My Guru is always with me, near at hand."),
                    punjabi: .init(default: TextPair(
                        akhar: "(hy BweI! myrw) gurU sdw myry nwl v`sdw hY myry AMg-sMg rihMdw hY[",
                        unicode: "(ਹੇ ਭਾਈ! ਮੇਰਾ) ਗੁਰੂ ਸਦਾ ਮੇਰੇ ਨਾਲ ਵੱਸਦਾ ਹੈ ਮੇਰੇ ਅੰਗ-ਸੰਗ ਰਹਿੰਦਾ ਹੈ।"
                    )),
                    spanish: "Tu Guru siempre te brinda Compañía;"
                ),
                transliteration: Transliteration(
                    english: .init(text: "gur merai sang sadaa hai naale |", larivaar: "gur​merai​sang​sadaa​hai​naale​|"),
                    devanagari: .init(text: "गुरु मेरै संगि सदा है नाले ॥", larivaar: "गुरु​मेरै​संगि​सदा​है​नाले​॥")
                ),
                firstletters: TextPair(akhar: "gmsshn", unicode: "ਗਮਸਸਹਨ"),
                linenum: 3
            )
        ),
        ShabadLineWrapper(
            line: LineOfShabad(
                id: "4ZD2",
                type: 3,
                gurmukhi: TextPair(akhar: "ismir ismir iqsu sdw sm@wly ]1] rhwau ]", unicode: "ਸਿਮਰਿ ਸਿਮਰਿ ਤਿਸੁ ਸਦਾ ਸਮੑਾਲੇ ॥੧॥ ਰਹਾਉ ॥"),
                larivaar: TextPair(akhar: "ismir​ismir​iqsu​sdw​sm@wly​]1]​rhwau​]", unicode: "ਸਿਮਰਿ​ਸਿਮਰਿ​ਤਿਸੁ​ਸਦਾ​ਸਮੑਾਲੇ​॥੧॥​ਰਹਾਉ​॥"),
                translation: Translation(
                    english: .init(default: "Meditating, meditating in remembrance on Him, I cherish Him forever. ||1||Pause||"),
                    punjabi: .init(default: TextPair(
                        akhar: "(gurU dI hI ikrpw nwl) mYN aus (prmwqmw) ƒ sdw ismr ky sdw Awpxy ihrdy ivc vsweI r`Kdw hW ]1] rhwau ]",
                        unicode: "(ਗੁਰੂ ਦੀ ਹੀ ਕਿਰਪਾ ਨਾਲ) ਮੈਂ ਉਸ (ਪਰਮਾਤਮਾ) ਨੂੰ ਸਦਾ ਸਿਮਰ ਕੇ ਸਦਾ ਆਪਣੇ ਹਿਰਦੇ ਵਿਚ ਵਸਾਈ ਰੱਖਦਾ ਹਾਂ ॥੧॥ ਰਹਾਉ ॥"
                    )),
                    spanish: "así es que reside en Él y Aprécialo siempre. (1-Pausa)"
                ),
                transliteration: Transliteration(
                    english: .init(text: "simar simar tis sadaa samaale |1| rahaau |", larivaar: "simar​simar​tis​sadaa​samaale​|1|​rahaau​|"),
                    devanagari: .init(text: "सिमरि सिमरि तिसु सदा समाले ॥१॥ रहाउ ॥", larivaar: "सिमरि​सिमरि​तिसु​सदा​समाले​॥१॥​रहाउ​॥")
                ),
                firstletters: TextPair(akhar: "ssqss", unicode: "ਸਸਤਸਸ"),
                linenum: 3
            )
        ),
        ShabadLineWrapper(
            line: LineOfShabad(
                id: "2GYN",
                type: 4,
                gurmukhi: TextPair(akhar: "qyrw kIAw mITw lwgY ]", unicode: "ਤੇਰਾ ਕੀਆ ਮੀਠਾ ਲਾਗੈ ॥"),
                larivaar: TextPair(akhar: "qyrw​kIAw​mITw​lwgY​]", unicode: "ਤੇਰਾ​ਕੀਆ​ਮੀਠਾ​ਲਾਗੈ​॥"),
                translation: Translation(
                    english: .init(default: "Your actions seem so sweet to me."),
                    punjabi: .init(default: TextPair(
                        akhar: "(hy pRBU! ieh qyry imlwey hoey gurU dI myhr hY ik) mYƒ qyrw kIqw hoieAw hryk kMm cMgw l`g irhw hY,",
                        unicode: "(ਹੇ ਪ੍ਰਭੂ! ਇਹ ਤੇਰੇ ਮਿਲਾਏ ਹੋਏ ਗੁਰੂ ਦੀ ਮੇਹਰ ਹੈ ਕਿ) ਮੈਨੂੰ ਤੇਰਾ ਕੀਤਾ ਹੋਇਆ ਹਰੇਕ ਕੰਮ ਚੰਗਾ ਲੱਗ ਰਿਹਾ ਹੈ,"
                    )),
                    spanish: "Dulces son para mí Tus acciones,"
                ),
                transliteration: Transliteration(
                    english: .init(text: "teraa keea meetthaa laagai |", larivaar: "teraa​keea​meetthaa​laagai​|"),
                    devanagari: .init(text: "तेरा कीआ मीठा लागै ॥", larivaar: "तेरा​कीआ​मीठा​लागै​॥")
                ),
                firstletters: TextPair(akhar: "qkml", unicode: "ਤਕਮਲ"),
                linenum: 4
            )
        ),
        ShabadLineWrapper(
            line: LineOfShabad(
                id: "AAB6",
                type: 4,
                gurmukhi: TextPair(akhar: "hir nwmu pdwrQu nwnku mWgY ]2]42]93]", unicode: "ਹਰਿ ਨਾਮੁ ਪਦਾਰਥੁ ਨਾਨਕੁ ਮਾਂਗੈ ॥੨॥੪੨॥੯੩॥"),
                larivaar: TextPair(akhar: "hir​nwmu​pdwrQu​nwnku​mWgY​]2]42]93]", unicode: "ਹਰਿ​ਨਾਮੁ​ਪਦਾਰਥੁ​ਨਾਨਕੁ​ਮਾਂਗੈ​॥੨॥੪੨॥੯੩॥"),
                translation: Translation(
                    english: .init(default: "Nanak begs for the treasure of the Naam, the Name of the Lord. ||2||42||93||"),
                    punjabi: .init(default: TextPair(
                        akhar: "qy (qyrw dws) nwnk qyry pwsoN sB qoN kImqI vsq qyrw nwm mMg irhw hY ]2]42]93]",
                        unicode: "ਤੇ (ਤੇਰਾ ਦਾਸ) ਨਾਨਕ ਤੇਰੇ ਪਾਸੋਂ ਸਭ ਤੋਂ ਕੀਮਤੀ ਵਸਤ ਤੇਰਾ ਨਾਮ ਮੰਗ ਰਿਹਾ ਹੈ ॥੨॥੪੨॥੯੩॥"
                    )),
                    spanish: "oh Señor, y no busco ninguna otra Bendición más que Tu Nombre. (2-42-93)"
                ),
                transliteration: Transliteration(
                    english: .init(text: "har naam padaarath naanak maangai |2|42|93|", larivaar: "har​naam​padaarath​naanak​maangai​|2|42|93|"),
                    devanagari: .init(text: "हरि नामु पदारथु नानकु मांगै ॥२॥४२॥९३॥", larivaar: "हरि​नामु​पदारथु​नानकु​मांगै​॥२॥४२॥९३॥")
                ),
                firstletters: TextPair(akhar: "hnpnm", unicode: "ਹਨਪਨਮ"),
                linenum: 4
            )
        ),
    ],
    error: false
)
