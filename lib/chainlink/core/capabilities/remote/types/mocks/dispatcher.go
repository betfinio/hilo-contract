// Code generated by mockery v2.43.2. DO NOT EDIT.

package mocks

import (
	types "github.com/smartcontractkit/chainlink/v2/core/capabilities/remote/types"
	ragep2ptypes "github.com/smartcontractkit/libocr/ragep2p/types"
	mock "github.com/stretchr/testify/mock"
)

// Dispatcher is an autogenerated mock type for the Dispatcher type
type Dispatcher struct {
	mock.Mock
}

// RemoveReceiver provides a mock function with given fields: capabilityId, donId
func (_m *Dispatcher) RemoveReceiver(capabilityId string, donId string) {
	_m.Called(capabilityId, donId)
}

// Send provides a mock function with given fields: peerID, msgBody
func (_m *Dispatcher) Send(peerID ragep2ptypes.PeerID, msgBody *types.MessageBody) error {
	ret := _m.Called(peerID, msgBody)

	if len(ret) == 0 {
		panic("no return value specified for Send")
	}

	var r0 error
	if rf, ok := ret.Get(0).(func(ragep2ptypes.PeerID, *types.MessageBody) error); ok {
		r0 = rf(peerID, msgBody)
	} else {
		r0 = ret.Error(0)
	}

	return r0
}

// SetReceiver provides a mock function with given fields: capabilityId, donId, receiver
func (_m *Dispatcher) SetReceiver(capabilityId string, donId string, receiver types.Receiver) error {
	ret := _m.Called(capabilityId, donId, receiver)

	if len(ret) == 0 {
		panic("no return value specified for SetReceiver")
	}

	var r0 error
	if rf, ok := ret.Get(0).(func(string, string, types.Receiver) error); ok {
		r0 = rf(capabilityId, donId, receiver)
	} else {
		r0 = ret.Error(0)
	}

	return r0
}

// NewDispatcher creates a new instance of Dispatcher. It also registers a testing interface on the mock and a cleanup function to assert the mocks expectations.
// The first argument is typically a *testing.T value.
func NewDispatcher(t interface {
	mock.TestingT
	Cleanup(func())
}) *Dispatcher {
	mock := &Dispatcher{}
	mock.Mock.Test(t)

	t.Cleanup(func() { mock.AssertExpectations(t) })

	return mock
}
