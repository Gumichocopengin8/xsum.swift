import Testing

@testable import Xsum

@Suite("Xsum tests") struct XsumTests {
    private func isValid(actual: Double, expected: Double) -> Bool {
        if actual.bitPattern == expected.bitPattern {
            return true
        }
        if actual.isNaN && expected.isNaN {
            return true
        }
        return false
    }

    func isSameValue(_ vec: [Double], _ expected: Double) {
        // XsumSmall
        var xsumSmall = XsumSmall()
        xsumSmall.addList(vec)
        #expect(isValid(actual: xsumSmall.sum(), expected: expected))

        xsumSmall = XsumSmall()
        for val in vec {
            xsumSmall.add(val)
        }
        #expect(isValid(actual: xsumSmall.sum(), expected: expected))

        xsumSmall.clear()
        #expect(isValid(actual: xsumSmall.sum(), expected: -0.0))

        // XsumLarge
        var xsumLarge = XsumLarge()
        xsumLarge.addList(vec)
        #expect(isValid(actual: xsumLarge.sum(), expected: expected))

        xsumLarge = XsumLarge()
        for val in vec {
            xsumLarge.add(val)
        }
        #expect(isValid(actual: xsumLarge.sum(), expected: expected))

        xsumLarge.clear()
        #expect(isValid(actual: xsumLarge.sum(), expected: -0.0))

        // XsumAuto
        var xsumAuto = XsumAuto()
        xsumAuto.addList(vec)
        #expect(isValid(actual: xsumAuto.sum(), expected: expected))

        xsumAuto = XsumAuto()
        for val in vec {
            xsumAuto.add(val)
        }
        #expect(isValid(actual: xsumAuto.sum(), expected: expected))

        xsumAuto.clear()
        #expect(isValid(actual: xsumAuto.sum(), expected: -0.0))

        // XsumVariant
        var xsumVariant =
            if vec.count > 1 {
                XsumVariant.large(XsumLarge())
            } else {
                XsumVariant.small(XsumSmall())
            }
        xsumVariant.addList(vec)
        #expect(isValid(actual: xsumVariant.sum(), expected: expected))

        xsumVariant =
            if vec.count <= 1 {
                XsumVariant.large(XsumLarge())
            } else {
                XsumVariant.small(XsumSmall())
            }
        for val in vec {
            xsumVariant.add(val)
        }
        #expect(isValid(actual: xsumVariant.sum(), expected: expected))

        xsumVariant.clear()
        #expect(isValid(actual: xsumVariant.sum(), expected: -0.0))

        // Xsum Extension
        #expect(isValid(actual: vec.xsum(), expected: expected))
    }

    @Test
    func basic() {
        isSameValue([1.0, 2.0, 3.0], 6.0)
        isSameValue([1e308], 1e308)
        isSameValue([1e308, -1e308], 0.0)
        isSameValue([0.1], 0.1)
        isSameValue([0.1, 0.1], 0.2)
        isSameValue([0.1, -0.1], 0.0)
        isSameValue(
            [1e308, 1e308, 0.1, 0.1, 1e30, 0.1, -1e30, -1e308, -1e308],
            0.30000000000000004,
        )
        isSameValue(
            [1e20, 0.1, -1e20, 1e20, 0.1, -1e20, 1e20, 0.1, -1e20],
            0.30000000000000004,
        )
        isSameValue([1e30, 0.1, -1e30], 0.1)
    }

    @Test
    func complex() {
        isSameValue(
            [
                8.98846567431158e+307,
                8.988_465_674_311_579e307,
                -1.797_693_134_862_315_7e308,
            ],
            9.9792015476736e+291,
        )
        isSameValue(
            [
                -5.630_637_621_603_525e255,
                9.565_271_205_476_345e307,
                2.993_760_464_302_079_7e292,
            ],
            9.565_271_205_476_347e307,
        )
        isSameValue(
            [
                6.739_986_666_787_661e66,
                2.0,
                -1.2689709186578243e-116,
                1.704_601_573_946_735_4e308,
                -9.979_201_547_673_601e291,
                6.160_926_733_208_294e307,
                -3.179_557_053_031_852e234,
                -7.027_282_978_772_846e307,
                -0.7500000000000001,
            ],
            1.61796594939028e+308,
        )
        isSameValue(
            [
                0.31150493246968836,
                -8.988_465_674_311_582e307,
                1.8315037361673755e-270,
                -15.999999999999996,
                2.9999999999999996,
                7.345_200_721_499_384e164,
                -2.033582473639399,
                -8.98846567431158e+307,
                -3.573_729_515_540_599_3e292,
                4.13894772383715e-124,
                -3.6111186457260667e-35,
                2.387_234_887_098_013e180,
                7.645295562778372e-298,
                3.395189016861822e-103,
                -2.6331611115768973e-149,
            ],
            -Double.infinity,
        )
        isSameValue(
            [
                -1.144_258_913_440_990_2e308,
                9.593_842_098_384_855e138,
                4.494_232_837_155_791e307,
                -1.348_269_851_146_736_7e308,
                4.494_232_837_155_792e307,
            ],
            -1.593_682_197_156_568_5e308,
        )
        isSameValue(
            [
                -1.144_258_913_440_990_2e308,
                4.494_232_837_155_791e307,
                -1.348_269_851_146_736_7e308,
                4.494_232_837_155_792e307,
            ],
            -1.593_682_197_156_568_7e308,
        )
        isSameValue(
            [
                9.593_842_098_384_855e138,
                -6.948_356_297_254_111e307,
                -1.348_269_851_146_736_7e308,
                4.494_232_837_155_792e307,
            ],
            -1.593_682_197_156_568_5e308,
        )
        isSameValue(
            [
                -2.534_858_246_857_893e115,
                8.988_465_674_311_579e307,
                8.98846567431158e+307,
            ],
            1.797_693_134_862_315_7e308,
        )
        isSameValue(
            [
                1.358_812_489_418_619_3e308,
                1.480_398_620_115_200_6e223,
                6.741_349_255_733_684e307,
            ],
            Double.infinity,
        )
        isSameValue(
            [
                6.741_349_255_733_684e307,
                1.797_693_134_862_315_5e308,
                -7.388_327_292_663_961e41,
            ],
            Double.infinity,
        )
        isSameValue(
            [
                -1.980_704_062_856_609_3e28,
                1.797_693_134_862_315_7e308,
                9.9792015476736e+291,
            ],
            1.797_693_134_862_315_7e308,
        )
        isSameValue(
            [
                -1.021_455_799_117_396_4e61,
                1.797_693_134_862_315_7e308,
                8.98846567431158e+307,
                -8.988_465_674_311_579e307,
            ],
            1.797_693_134_862_315_7e308,
        )
        isSameValue(
            [
                1.797_693_134_862_315_7e308,
                7.999999999999999,
                -1.908963895403937e-230,
                1.644_595_008_232_026_4e292,
                2.073_485_670_760_580_6e205,
            ],
            Double.infinity,
        )
        isSameValue(
            [
                6.197409167220438e-223,
                -9.979_201_547_673_601e291,
                -1.797_693_134_862_315_7e308,
            ],
            -Double.infinity,
        )
        isSameValue(
            [
                4.49423283715579e+307,
                8.944_251_746_776_101e307,
                -0.0002441406250000001,
                1.175_206_071_004_381_7e308,
                4.940_846_717_201_632e292,
                -1.683_669_940_645_452_8e308,
            ],
            8.353_845_887_521_184e307,
        )
        isSameValue(
            [
                8.988_465_674_311_579e307,
                7.999999999999998,
                7.029158107234023e-308,
                -2.2303483759420562e-172,
                -1.797_693_134_862_315_7e308,
                -8.98846567431158e+307,
            ],
            -1.797_693_134_862_315_7e308,
        )
        isSameValue([8.98846567431158e+307, 8.98846567431158e+307], Double.infinity)
    }

    @Test
    func nanInfinity() {
        isSameValue([Double.nan], Double.nan)
        isSameValue([Double.nan, 2.4], Double.nan)
        isSameValue([Double.infinity, Double.nan], Double.nan)
        isSameValue([Double.infinity, Double.nan, 1.5], Double.nan)
        isSameValue([Double.infinity, -Double.infinity], Double.nan)
        isSameValue([-Double.infinity, Double.infinity], Double.nan)

        isSameValue([Double.infinity], Double.infinity)
        isSameValue([Double.infinity, 23.3], Double.infinity)
        isSameValue([Double.infinity, Double.infinity], Double.infinity)
        isSameValue([-Double.infinity], -Double.infinity)
        isSameValue([-Double.infinity, -Double.infinity], -Double.infinity)
    }

    @Test
    func zeros() {
        isSameValue([], -0.0)
        isSameValue([-0.0], -0.0)
        isSameValue([-0.0, -0.0], -0.0)
        isSameValue([-0.0, 0.0], 0.0)
        isSameValue([0.0], 0.0)
    }
}
