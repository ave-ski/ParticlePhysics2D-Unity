﻿

//Yves Wang @ FISH, 2015, All rights reserved

Shader "FISH/ParticlePhysics2D/SpringConstraint" {
	Properties {
		_PositionRT ("", 2D) = "white" {}
		_StateRT ("",2D) = "white" {}
		_SpringConstant ( "" , Range(0.001,0.99)) = 0.9
	}
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "ForceNoShadowCasting" = "True" }
		blend One One
		Zwrite off
		fog {mode off}
		
		CGINCLUDE
		#include "UnityCG.cginc"
		sampler2D _PositionRT;
		uniform sampler2D _StateRT;
		uniform float _SpringConstant;
		
		struct appdata_springVert {
			float3 vertex : POSITION;//vertex.xy = A texcocord, z = restlengt2
			float4 texco : TEXCOORD0;//xy = B texcoord, zw = delta, we can only set float2 uv from mono
		};
		
		struct v2f_spring {
			float2 pos : SV_POSITION;//screen space -1 to 1
			float2 delta : TEXCOORD0;//delta
		};
		
		float2 frag_spring(v2f_spring IN) : SV_Target{
			return IN.delta;
		}
		ENDCG
		
		Pass {
			Name "SpringDelta"
			ColorMask 0 //we dont need to output frag
			
			CGPROGRAM
			#pragma vertex vert_delta
			#pragma fragment frag_delta
			#pragma target 3.0
			
			v2f_spring vert_delta(appdata_springVert IN){
				v2f_spring OUT;
				float2 posA = tex2Dlod(_PositionRT , IN.vertex.xy);
				float2 posB = tex2Dlod(_PositionRT , IN.texco.xy);
				float2 delta = posA - posB;
				//delta *= restLength2 /(delta.sqrMagnitude + restLength2) - 0.5f;
				delta *= (IN.vertex.z / (delta.x * delta.x + delta.y * delta.y + IN.vertex.z) - 0.5) * _SpringConstant;
				IN.texco.zw = delta;//this is important, as we get the delta, which is to be used in the next passes
				//OUT.pos = IN.vertex;
				return OUT;
			}
			
			void frag_delta(v2f_spring i) : SV_Target {
				discard;
			}
			
			ENDCG
		}
		
		pass {
			Name "SpringParticleA"
			ColorMask RG
			CGPROGRAM
			#pragma vertex vert_A
			#pragma fragment frag_spring
			#pragma target 3.0
			
			v2f_spring vert_A (appdata_springVert IN) {
				v2f_spring OUT;
				OUT.pos = IN.vertex.xy * 2 - 1;
				OUT.delta = IN.texco.zw;
				return OUT;
			}
		
			ENDCG
			
		} 
		
		pass {
			Name "SpringParticleB"
			ColorMask RG
			CGPROGRAM
			#pragma vertex vert_B
			#pragma fragment frag_spring
			#pragma target 3.0
			
			v2f_spring vert_B (appdata_springVert IN) {
				v2f_spring OUT;
				OUT.pos = IN.texco.xy * 2 - 1;
				OUT.delta = IN.texco.zw;
				return OUT;
			}
			ENDCG
			
		}
		
	}
}