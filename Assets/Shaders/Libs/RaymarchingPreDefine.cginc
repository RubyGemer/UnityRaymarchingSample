#ifndef raymarching_pre_define_h
#define raymarching_pre_define_h

#include "UnityCG.cginc"
#include "Libs/Utils.cginc"
#include "Libs/Noise.cginc"
#include "Libs/Primitives.cginc"
#include "Libs/DistanceFunction.cginc"

#ifndef RAY_HIT_DISTANCE
#define RAY_HIT_DISTANCE 0.0001
#endif

// ���[���h���W�n�̃J�����̈ʒu
float3 GetCameraPosition() { return _WorldSpaceCameraPos; }
// �ϊ��s�񂩂�J�����̏����擾
float3 GetCameraForward() { return -UNITY_MATRIX_V[2].xyz; }
float3 GetCameraUp() { return UNITY_MATRIX_V[1].xyz; }
float3 GetCameraRight() { return UNITY_MATRIX_V[0].xyz; }
float3 GetCameraFocalLength() { return abs(UNITY_MATRIX_P[1][1]); }
// �J�����������_�����O����ő勗��
float GetCameraMaxDistance() { return _ProjectionParams.z - _ProjectionParams.y; }

// ���C�̕������擾
float3 GetRayDir(float2 screenPos)
{
#if UNITY_UV_STARTS_AT_TOP
	screenPos.y *= -1.0;
#endif
	screenPos.x *= _ScreenParams.x / _ScreenParams.y;

	float3 camDir = GetCameraForward();
	float3 camUp = GetCameraUp();
	float3 camSide = GetCameraRight();
	float3 focalLen = GetCameraFocalLength();

	return normalize((camSide * screenPos.x) + (camUp * screenPos.y) + (camDir * focalLen));
}

// �f�v�X�擾
float GetDepth(float3 pos)
{
	float4 vp = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
#if UNITY_UV_STARTS_AT_TOP
	return vp.z / vp.w;
#else
	return (vp.z / vp.w) * 0.5 + 0.5;
#endif
}

struct appdata
{
	float4 vertex : POSITION;
};

struct v2f
{
	float4 vertex		: SV_POSITION;
	float4 screenPos	: TEXCOORD0;
};

//MRT�ɂ��o�͂���G-Buffer
struct gbuffer
{
	half4 diffuse  : SV_Target0;	// rgb: diffuse,  a: occlusion
	half4 specular : SV_Target1;	// rgb: specular, a: smoothness
	half4 normal   : SV_Target2;	// rgb: normal,   a: unused
	half4 emission : SV_Target3;	// rgb: emission, a: unused
	float depth    : SV_Depth;		// Depth
};

struct raymarchOut
{
	float3 pos;		// ���[���h���W
	int count;		// ���s��
	float length;	// ���C���i�񂾒���
	float distance;	// �Ō�Ɏ��s���ꂽ�����֐��̏o��
};

struct transform
{
	float3 pos;
	float3 rot;
	float3 scale;
};

gbuffer InitGBuffer(half4 diffuse, half4 specular, half3 normal, half4 emission, float depth)
{
	gbuffer g;
	g.diffuse = diffuse;
	g.specular = specular;
	g.normal = half4(normal, 1);
	g.emission = emission;
	g.depth = depth;

	return g;
}

transform InitTransform(float3 pos, float3 rot, float3 scale) {
	transform tr;
	tr.pos = pos;
	tr.rot = rot;
	tr.scale = scale;

	return tr;
}

// ���[���h���W���烍�[�J�����W�ɕϊ�
float3 Localize(float3 pos, transform tr) {
	// Position
	pos -= tr.pos;

	// Rotation
	float3 x = rotateX(pos, radians(tr.rot.x));
	float3 xy = rotateY(x, radians(tr.rot.y));
	float3 xyz = rotateX(xy, radians(tr.rot.z));
	pos.xyz = xyz;

	// Scale
	pos /= tr.scale;

	return pos;
}

#endif // raymarching_pre_define_h